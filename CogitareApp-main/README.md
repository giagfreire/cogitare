# Cogitare App

App de protótipo para telas do projeto Cogitare (faculdade). Plataforma que conecta cuidadores, responsáveis e idosos para gestão de cuidados e contratos.

**Versão:** 1.0.0

---

## Funcionalidades

- **Autenticação** — Login por tipo de usuário (cuidador ou responsável).
- **Cadastros** — Cadastro de cuidador, idoso e responsável.
- **Dashboards** — Telas específicas para cuidador e responsável.
- **Cuidadores próximos** — Busca de cuidadores por proximidade.
- **Contratos e propostas** — Criação e listagem de contratos, propostas recebidas e detalhadas.
- **Atendimentos** — Histórico de serviços.
- **Onboarding** — Fluxo inicial e seleção de papel (quem está usando o app).

---

## Stack tecnológica

| Camada   | Tecnologias |
|----------|-------------|
| **App**  | Flutter (mobile, web, Windows). Dependências: `http`, `flutter_dotenv`, `shared_preferences`, `intl`. |
| **Backend** | Node.js, Express, MySQL (MariaDB). Middlewares: Helmet, CORS, rate limit, JWT. |
| **Banco** | `cogitare_bd` — schema e procedures em `cogitare_bd.sql`. |

---

## Estrutura do repositório

- **`lib/`** — App Flutter: `screens/`, `controllers/`, `models/`, `services/`, `widgets/`, `utils/`.
- **`backend/`** — API REST: `server.js`, `routes/` (auth, cuidador, idoso, endereco, responsavel, nearby_caregivers, contracts, atendimentos), `middleware/`.
- **`cogitare_bd.sql`** — Script do banco de dados.
- **`start-api.bat`** / **`start-api.sh`** — Scripts para subir a API.

---

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/)
- Node.js
- MySQL ou MariaDB (ou acesso a um banco remoto)

---

## Como rodar

### 1. Banco de dados

Se for usar banco local, importe o script `cogitare_bd.sql` no seu MySQL/MariaDB. As credenciais e URLs devem ser configuradas via arquivos `.env` (não versionados); nunca commite senhas no repositório.

### 2. Backend (API)

1. Entre na pasta do backend: `cd backend`
2. Copie o arquivo de exemplo de ambiente: use `env_example.txt` como referência e crie um `.env` na pasta `backend/` com as variáveis necessárias (banco, porta, JWT, etc.).
3. Instale as dependências: `npm install`
4. Inicie o servidor: `node server.js`  
   Ou use os scripts na raiz do projeto: `start-api.bat` (Windows) ou `start-api.sh` (Linux/macOS).

A API ficará disponível em `http://localhost:3000` (ou na porta definida no `.env`).

### 3. App Flutter

1. Na raiz do projeto, configure um `.env` com a URL base da API (por exemplo, `API_BASE_URL=http://localhost:3000`). Use o `.env` já referenciado no projeto e não versionado.
2. Instale as dependências: `flutter pub get`
3. Execute: `flutter run` (e escolha o dispositivo ou web, se necessário).

---

## Documentação Flutter

Para mais detalhes sobre desenvolvimento com Flutter: [documentação oficial](https://docs.flutter.dev/).
