'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'connecta-trip-test-'));
process.env.DATA_FILE = path.join(dir, 'dados.json');
const {iniciarServidor} = require('../server');
const server = iniciarServidor(0);
let base;
test.before(async () => {
  if (!server.listening) await new Promise(resolve => server.once('listening', resolve));
  base = `http://127.0.0.1:${server.address().port}`;
});

test.after(async () => {
  await new Promise(resolve => server.close(resolve));
  fs.rmSync(dir, {recursive: true, force: true});
});
async function req(metodo, rota, dados, token) {
  const r = await fetch(base + rota, {method: metodo,
    headers: { 'Content-Type':'application/json', ...(token ? {Authorization:`Bearer ${token}`} : {})},
    ...(dados ? {body: JSON.stringify(dados)} : {})});
  return {status: r.status, body: await r.json()};
}
const senha = 'Senha#12345';
let viajante, consultor1, consultor2, consultor3, outroViajante, viagem, proposta1, proposta2;

test('health check', async () => {
  const r = await req('GET', '/health');
  assert.equal(r.status, 200); assert.equal(r.body.ok, true);
});
test('cadastro e perfis distintos', async () => {
  const cad = async (nome, email, perfil) => req('POST', '/auth/register', {nome, email, senha, perfil});
  viajante = (await cad('Maria Viajante', 'maria@exemplo.test', 'viajante')).body;
  consultor1 = (await cad('Ana Consultora', 'ana@exemplo.test', 'consultor')).body;
  consultor2 = (await cad('Bruno Consultor', 'bruno@exemplo.test', 'consultor')).body;
  consultor3 = (await cad('Clara Consultora', 'clara@exemplo.test', 'consultor')).body;
  outroViajante = (await cad('Pedro Viajante', 'pedro@exemplo.test', 'viajante')).body;
  assert.ok(viajante.token && consultor1.token && outroViajante.token);
  assert.equal(consultor1.usuario.perfil, 'consultor');
});
test('recusa duplicata e login com senha incorreta', async () => {
  assert.equal((await req('POST', '/auth/register', {nome:'Repetido', email:'maria@exemplo.test', senha, perfil:'viajante'})).status,409);
  assert.equal((await req('POST', '/auth/login', {email:'maria@exemplo.test', senha:'nao'})).status,401);
  assert.equal((await req('POST', '/auth/login', {email:'maria@exemplo.test', senha})).status,200);
});
test('acesso sem token não recebe viagens', async () => {
  assert.equal((await req('GET', '/trips')).status,401);
});
test('somente viajante cria solicitação válida', async () => {
  const inicio = new Date(Date.now()+86400000*20).toISOString();
  const fim = new Date(Date.now()+86400000*27).toISOString();
  const dados = {destinoId:'1', inicio, fim, viajantes:2, orcamento:'R$ 5 mil a R$ 10 mil',
    interesses:['Passagem','Hospedagem'], observacoes:'Quero traslado',
    roteiro:[{dia:1,titulo:'Chegada',descricao:'Chegada ao aeroporto'}]};
  assert.equal((await req('POST','/trips',dados,consultor1.token)).status,403);
  const res = await req('POST','/trips',dados,viajante.token);
  assert.equal(res.status,201); viagem = res.body.viagem;
  assert.equal(viagem.status,'enviada');
  assert.equal(viagem.donoId,viajante.usuario.id);
});
test('não aceita dados inválidos e datas passadas', async () => {
  const r = await req('POST','/trips',{destinoId:'2', inicio:'2000-01-01', fim:'2000-01-03',
    viajantes:0, orcamento:'X', interesses:[], observacoes:''},viajante.token);
  assert.equal(r.status,400);
});
test('isolamento de dados do outro viajante', async () => {
  const r = await req('GET','/trips',null,outroViajante.token);
  assert.equal(r.status,200); assert.equal(r.body.viagens.length,0);
  assert.equal((await req('GET',`/trips/${viagem.id}`,null,outroViajante.token)).status,404);
});
test('consultor inicia análise', async () => {
  const r = await req('POST',`/trips/${viagem.id}/analyze`,{},consultor1.token);
  assert.equal(r.status,200); assert.equal(r.body.viagem.status,'emAnalise');
});
test('dois consultores enviam propostas comparáveis', async () => {
  const p = valor => ({valorEstimado:valor, itensIncluidos:['Hospedagem','Passagem'],
    condicoes:'Pagamento direto com consultor', validade:new Date(Date.now()+86400000*15).toISOString()});
  let r = await req('POST',`/trips/${viagem.id}/proposals`,p(12500),consultor1.token);
  assert.equal(r.status,200); proposta1 = r.body.viagem.propostas[0];
  r = await req('POST',`/trips/${viagem.id}/proposals`,p(11800),consultor2.token);
  assert.equal(r.status,200); proposta2 = r.body.viagem.propostas[1];
  assert.equal(r.body.viagem.propostas.length,2);
  assert.equal(r.body.viagem.status,'propostaRecebida');
});
test('não pode duplicar ou alterar proposta alheia', async () => {
  const r = await req('POST',`/trips/${viagem.id}/proposals`,{
    valorEstimado:9000, itensIncluidos:['Hotel'], condicoes:'X',
    validade:new Date(Date.now()+86400000).toISOString()},consultor1.token);
  assert.equal(r.status,400);
  assert.equal((await req('POST',`/trips/${viagem.id}/accept`,{propostaId:proposta1.id},consultor1.token)).status,403);
});
test('viajante aceita uma proposta e somente o consultor escolhido encerra', async () => {
  const r = await req('POST',`/trips/${viagem.id}/accept`,{propostaId:proposta2.id},viajante.token);
  assert.equal(r.status,200); assert.equal(r.body.viagem.status,'aceita');
  assert.equal((await req('POST',`/trips/${viagem.id}/close`,{},consultor1.token)).status,403);
  assert.equal((await req('POST',`/trips/${viagem.id}/close`,{},consultor2.token)).status,200);
});
test('avaliação após encerrar e bloqueio de avaliações repetidas', async () => {
  assert.equal((await req('POST',`/trips/${viagem.id}/review`,{nota:4, comentario:'Ótimo atendimento'},outroViajante.token)).status,404);
  const r = await req('POST',`/trips/${viagem.id}/review`,{nota:5, comentario:'Ótimo atendimento'},viajante.token);
  assert.equal(r.status,200); assert.equal(r.body.viagem.avaliacao.nota,5);
  assert.equal((await req('POST',`/trips/${viagem.id}/review`,{nota:1, comentario:''},viajante.token)).status,409);
});
test('persistência e histórico continuam após novas requisições', async () => {
  const r = await req('GET',`/trips/${viagem.id}`,null,viajante.token);
  assert.equal(r.body.viagem.propostas.length,2);
  assert.equal(r.body.viagem.status,'encerrada');
  assert.ok(r.body.viagem.historico.length >= 6);
  assert.ok(fs.existsSync(process.env.DATA_FILE));
});

let mensagem;
test('lista de consultores corresponde a contas cadastradas', async () => {
  const r = await req('GET', '/consultants', null, viajante.token);
  assert.equal(r.status, 200);
  assert.equal(r.body.consultores.length, 3);
});
test('viajante consegue enviar mensagem real para consultor cadastrado', async () => {
  const r = await req('POST', '/messages', {consultorId: consultor1.usuario.id,
    assunto: 'Cancún', texto: 'Gostaria de saber as opções.'}, viajante.token);
  assert.equal(r.status, 201);
  mensagem = r.body.mensagem;
  assert.equal(mensagem.consultorId, consultor1.usuario.id);
});
test('consultores veem somente mensagens próprias e resposta de outro é proibida', async () => {
  let r = await req('GET', '/messages', null, consultor2.token);
  assert.equal(r.body.mensagens.length, 0);
  r = await req('POST', `/messages/${mensagem.id}/reply`, {resposta:'Não posso responder'}, consultor2.token);
  assert.equal(r.status,403);
});
test('consultor responde, e viajante consulta resposta persistida', async () => {
  const r = await req('POST', `/messages/${mensagem.id}/reply`,
    {resposta:'Podemos conversar sobre Cancún!'}, consultor1.token);
  assert.equal(r.status,200);
  const consulta = await req('GET', '/messages', null, viajante.token);
  assert.equal(consulta.status,200);
  assert.equal(consulta.body.mensagens[0].resposta,'Podemos conversar sobre Cancún!');
  assert.equal((await req('POST', `/messages/${mensagem.id}/reply`,
    {resposta:'Outra resposta'}, consultor1.token)).status,409);
});

// O Chrome precisa de preflight CORS para enviar JSON e Authorization.
test('CORS permite preflight de localhost com Authorization', async () => {
  const origem = 'http://localhost:7357';
  const r = await fetch(base + '/auth/register', {method: 'OPTIONS', headers: {
    Origin: origem, 'Access-Control-Request-Method': 'POST',
    'Access-Control-Request-Headers': 'Content-Type, Authorization',
  }});
  assert.equal(r.status, 204);
  assert.equal(r.headers.get('access-control-allow-origin'), origem);
  assert.match(r.headers.get('access-control-allow-headers'), /Authorization/);
});
test('CORS bloqueia preflight de uma origem externa', async () => {
  const r = await fetch(base + '/auth/register', {method: 'OPTIONS', headers: {
    Origin: 'https://exemplo-externo.invalid',
    'Access-Control-Request-Method': 'POST',
  }});
  assert.equal(r.status, 403);
});

test('serviços de traslado e seguro são aceitos e persistidos', async () => {
  const inicio = new Date(Date.now()+86400000*35).toISOString();
  const fim = new Date(Date.now()+86400000*40).toISOString();
  const dados = {destinoId:'2', inicio, fim, viajantes:3, orcamento:'Até R$ 5 mil',
    interesses:['Traslado','Seguro'],
    observacoes:'Traslado privativo; 2 bagagens. Seguro ampliado.'};
  const criado = await req('POST','/trips',dados,viajante.token);
  assert.equal(criado.status,201);
  assert.deepEqual(criado.body.viagem.interesses,['Traslado','Seguro']);
  const recarregado = await req('GET',`/trips/${criado.body.viagem.id}`,null,viajante.token);
  assert.equal(recarregado.status,200);
  assert.equal(recarregado.body.viagem.observacoes,dados.observacoes);
});

test('interesses desconhecidos continuam bloqueados na API', async () => {
  const inicio = new Date(Date.now()+86400000*35).toISOString();
  const fim = new Date(Date.now()+86400000*40).toISOString();
  const res = await req('POST','/trips',{destinoId:'2',inicio,fim,viajantes:2,
    orcamento:'Até R$ 5 mil', interesses:['Cobrança indevida'],observacoes:''},viajante.token);
  assert.equal(res.status,400);
});
