# Connecta Trip

**Planejamento de viagens, solicitação de orçamentos e acompanhamento de propostas em um aplicativo mobile.**

Projeto semestral da disciplina **Desenvolvimento Mobile Nativo (SIS918)**, curso de **Sistemas de Informação — UNEX**, orientado pelo professor **Wallas Froes de Oliveira**.

**Equipe:** Joabe Gomes, João Marcelo, Kevilyn Bitencourt, Felipe Miranda, Igor Flôres, Pedro Almeida e Rhuan Cassius.

## 1. Sobre o projeto

O Connecta Trip foi criado para organizar a comunicação entre viajantes e consultores. O viajante informa destino, período, número de pessoas, orçamento e serviços desejados. O consultor analisa o pedido e apresenta uma proposta estruturada. O sistema registra o andamento e permite comparar propostas.

Trata-se de um **MVP acadêmico**: as opções de hospedagem são referências demonstrativas e as rotas aéreas são ilustrativas. **Não há consulta de preços ou disponibilidade em tempo real, emissão de passagens, contratação de seguro, reservas ou pagamentos.** A confirmação comercial depende do consultor.

## 2. Funcionalidades

### Viajante

- Cadastro, login e perfil pessoal.
- Home, busca por destinos, favoritos e detalhes dos pacotes.
- **Hotéis:** opções de referência por destino, filtro Hotel/Resort e seleção para orçamento.
- **Passagens:** consulta demonstrativa de rotas, origem e preferência de classe.
- **Traslado:** escolha entre privativo e compartilhado, local de embarque e bagagens.
- **Seguro viagem:** seleção de interesse em cobertura essencial ou ampliada.
- **Orçamento:** formulário em quatro etapas, com campos obrigatórios e validação de datas.
- Acompanhamento do status do pedido, histórico, mensagens, comparação de propostas, aceite e avaliação.

### Consultor

- Cadastro com perfil de consultor e acesso à fila de solicitações.
- Início da análise de pedidos, troca de mensagens e envio de proposta.
- Proposta com valor estimado, itens incluídos, condições e validade.
- Encerramento restrito ao consultor da proposta aceita.

Os serviços escolhidos no catálogo são encaminhados para **interesses e observações** da solicitação, permitindo ao consultor considerar essas preferências na proposta.

## 3. Tecnologias e arquitetura

| Camada | Tecnologias | Responsabilidade |
|---|---|---|
| Interface mobile | Flutter, Dart, Material Design 3 | Telas, navegação, validações e interação |
| Organização | MVP: Models, Views, Presenters e Services | Separação entre apresentação e regras |
| Persistência mobile | SQLite (`sqflite`, `path`) | Dados locais no Android |
| Persistência web | `shared_preferences` | Dados locais de demonstração no navegador |
| Comunicação | HTTP / JSON | Consumo da API quando configurada |
| Backend | Node.js, API REST | Autenticação, regras e dados compartilhados |
| Armazenamento do servidor | Arquivo JSON local | Persistência simples do MVP; não é banco SQL de produção |

**Dois modos de uso:**

- **Offline (sem `API_URL`):** informações salvas no dispositivo; útil para demonstração com contas no mesmo aparelho.
- **Com API (com `API_URL`):** o servidor é a fonte dos dados de usuários e solicitações, acessível a dispositivos conectados a ele. Há cache local para informações recuperadas. Os dados dos dois modos **não são sincronizados automaticamente**.

## 4. Estrutura do repositório

```text
Connecta_Trip_Completo/
├── lib/
│   ├── data/          # Banco local
│   ├── models/        # Entidades e serialização
│   ├── presenters/    # Estado e validações
│   ├── services/      # Operações e regras de negócio
│   ├── views/         # Telas Flutter
│   ├── widgets/       # Componentes reutilizáveis
│   ├── utils/         # Rotas, cores e utilitários
│   └── main.dart
├── assets/             # Recursos visuais
├── android/            # Configuração Android
├── backend/
│   ├── server.js       # API REST
│   └── test/           # Testes da API
├── test/               # Testes Dart/Flutter
├── pubspec.yaml        # Dependências Flutter
└── README.md
```

## 5. Como executar no VS Code e Android Studio (Windows)

### Pré-requisitos

1. Instalar **Flutter SDK** com Dart e configurar `flutter/bin` no PATH.
2. Instalar **VS Code** e extensões **Flutter** e **Dart**.
3. Instalar **Android Studio**, Android SDK, NDK solicitado pelo Gradle e criar um emulador no **Device Manager**; pode ser usado celular real com depuração USB.
4. Para o modo conectado, instalar **Node.js 20 ou superior**.
5. No Windows, habilitar o **Modo de Desenvolvedor** se o Flutter solicitar suporte a links simbólicos.

É recomendado colocar o projeto em um caminho simples, fora do OneDrive e sem acentos, por exemplo `C:\projetos\Connecta_Trip_Completo`.

### Preparar o aplicativo

No VS Code, abra a **pasta raiz que contém `pubspec.yaml`**. Em um terminal PowerShell:

```powershell
cd C:\projetos\Connecta_Trip_Completo
flutter doctor
flutter pub get
flutter devices
```

Abra o Android Studio > **Device Manager** e inicie o emulador. Confirme seu identificador com `flutter devices` (por exemplo, `emulator-5554`).

### Opção A — executar em modo offline

```powershell
flutter run -d emulator-5554
```

Nesse modo, a aplicação utiliza armazenamento local. Para demonstrar os dois perfis, use contas diferentes no mesmo emulador.

### Opção B — executar com a API REST (recomendado para testar integração)

Abra **dois terminais**.

**Terminal 1 — servidor:**

```powershell
cd C:\projetos\Connecta_Trip_Completo\backend
node server.js
```

A API deve informar `Connecta Trip API: http://localhost:3000`. É possível testar a disponibilidade em `http://localhost:3000/health`. Deixe esse terminal aberto.

**Terminal 2 — aplicativo Android:**

```powershell
cd C:\projetos\Connecta_Trip_Completo
flutter pub get
flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:3000
```

`10.0.2.2` é o endereço especial usado pelo **emulador Android** para acessar o servidor do computador. Em um **celular físico**, utilize o IP local do computador e verifique a rede/firewall; `10.0.2.2` não funciona nele.

**Chrome (uso complementar):** com o servidor em execução, pode ser utilizado `flutter run -d chrome --dart-define=API_URL=http://localhost:3000`. O produto alvo da disciplina é o aplicativo Android.

### Problemas comuns de instalação

- `flutter não é reconhecido`: confira o PATH e reabra o terminal.
- `Device emulator ... offline`: espere o Android iniciar; tente **Cold Boot Now** no Device Manager.
- `Your project path contains non-ASCII characters`: mova o projeto para um caminho sem acentos.
- `NDK ... not installed`: Android Studio > SDK Manager > SDK Tools > Show Package Details > NDK (Side by side); instale a versão solicitada.
- `Timeout waiting to lock build logic queue`: não execute duas compilações ao mesmo tempo; pare daemons Gradle e feche builds simultâneos.
- Não é necessário instalar **Visual Studio com C++** para compilar o aplicativo Android.

## 6. Roteiro de demonstração dos dois perfis

1. Crie uma conta **Viajante** e entre no aplicativo.
2. Em **Hotéis**, escolha destino e referência de hospedagem; confirme o interesse no orçamento.
3. Em **Passagens**, selecione rota de pesquisa e classe. Nos detalhes de pacote, experimente **Traslado** e **Seguro**.
4. Envie uma solicitação com datas futuras, quantidade de viajantes, orçamento e observações.
5. Confira o status **Enviada** em **Viagens**.
6. Saia da conta e entre como **Consultor**; abra a solicitação, inicie análise e envie uma proposta com valor, itens, condições e validade.
7. Entre com outro consultor e envie uma segunda proposta para comparar.
8. Volte ao viajante, compare as propostas e aceite uma.
9. Com a conta do consultor escolhido, encerre o atendimento.
10. Volte ao viajante, registre uma avaliação e confira o histórico após reabrir o aplicativo.

Use contas e valores **fictícios** na apresentação. Não exponha dados pessoais de usuários.

## 7. Testes

Na raiz:

```powershell
flutter analyze
flutter test
```

No backend:

```powershell
cd backend
npm test
```

A suíte da API foi executada com Node.js 22.16.0 e apresentou **21 testes aprovados, 0 falhas**. Inclui cadastro, login, permissões, solicitações, propostas, histórico, mensagens, CORS e interesses em Traslado e Seguro. Esses testes **não substituem** a execução de `flutter analyze`, `flutter test` nem os testes manuais de interface no Android.

A avaliação de usabilidade com pelo menos três participantes deve ser realizada e registrada pelo grupo em documento de entrega separado, com as tarefas, observações e resultados efetivamente coletados.

## 8. Limitações e uso responsável

O aplicativo é um protótipo acadêmico. Os hotéis são exemplos de referência e os itinerários de passagens são ilustrativos. Não há inventário nem tarifas em tempo real, contratação de traslado/seguro, integração com meios de pagamento ou emissão de bilhetes. A API usa armazenamento em JSON e não deve ser exposta publicamente como um serviço de produção. A aplicação real exigiria infraestrutura segura, aprimoramento do controle de acesso e revisão dos requisitos de proteção de dados.

## 9. Referências técnicas

- [Flutter](https://docs.flutter.dev/)
- [Dart](https://dart.dev/language)
- [SQLite](https://www.sqlite.org/docs.html)
- [Node.js](https://nodejs.org/docs/latest/api/)
- [HTTP Semantics (RFC 9110)](https://www.rfc-editor.org/rfc/rfc9110)
- [OWASP MASVS](https://mas.owasp.org/MASVS/)

**Connecta Trip — projeto acadêmico de Sistemas de Informação, UNEX.**
