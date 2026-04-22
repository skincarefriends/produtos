# SkinCareFriends

Vitrine de skincare com painel admin (cadastro/edição/remoção de produtos), imagens hospedadas no Cloudinary e dados em MongoDB.

## Stack

- Node.js 18+ / Express
- MongoDB (Mongoose)
- Cloudinary (upload direto via multer)
- Sessão simples (`express-session`) com credenciais fixas via `.env`
- Front estático servido de `public/` (Tailwind via CDN)

## Rodar localmente

**Opção A — Node puro (precisa ter um Mongo rodando):**

```bash
npm install
cp .env.example .env   # ajuste MONGODB_URI / SESSION_SECRET
npm start
```

**Opção B — Docker Compose (sobe app + Mongo juntos):**

```bash
cp .env.example .env
docker compose up --build
```

O compose sobrescreve `MONGODB_URI` pra apontar pro serviço `mongo` interno; o volume `mongo_data` persiste os dados.

Acesse:

- `http://localhost:3000` — vitrine pública
- `http://localhost:3000/login` — login do painel
- `http://localhost:3000/admin` — painel (exige login)

## Variáveis de ambiente (`.env`)

| Variável                | Descrição                                                      |
| ----------------------- | -------------------------------------------------------------- |
| `PORT`                  | Porta HTTP (Railway injeta automaticamente)                    |
| `NODE_ENV`              | `production` em deploy                                         |
| `ADMIN_USER`            | Usuário do painel                                              |
| `ADMIN_PASS`            | Senha do painel                                                |
| `SESSION_SECRET`        | String aleatória longa (troque em produção)                    |
| `MONGODB_URI`           | Connection string do Mongo (Railway plugin ou Atlas)           |
| `CLOUDINARY_CLOUD_NAME` | `dyhjjms8y`                                                    |
| `CLOUDINARY_API_KEY`    | API key                                                        |
| `CLOUDINARY_API_SECRET` | API secret                                                     |
| `CLOUDINARY_FOLDER`     | Pasta destino (default `skincarefriends`)                      |

## Deploy no Railway (IaC)

**Recomendado — via script (provisiona tudo do zero):**

```bash
# 1. Instale e logue a CLI
npm i -g @railway/cli   # ou: curl -fsSL https://railway.com/install.sh | sh
railway login

# 2. Garanta que .env está preenchido (Cloudinary + ADMIN_* + SESSION_SECRET)

# 3. Rode o setup
bash scripts/railway-setup.sh [nome-do-projeto]
```

O script faz:

1. `railway init` — cria o projeto.
2. `railway add --database mongo` — provisiona o plugin MongoDB.
3. Lê o `.env` linha a linha e seta cada variável no serviço web, trocando `MONGODB_URI` por uma referência ao plugin (`${{ MongoDB.MONGO_URL }}`), então a URI fica sempre sincronizada.
4. `railway up --detach` — build + deploy.
5. `railway domain` — gera a URL pública.

**Manual (dashboard):**

1. `New Project → Deploy from GitHub` com este repo.
2. `+ New → Database → MongoDB`.
3. Na aba **Variables** do serviço web, cole tudo do `.env` e substitua `MONGODB_URI` por `${{ MongoDB.MONGO_URL }}`.
4. Railway detecta `railway.json` e `Procfile` automaticamente. Healthcheck em `/healthz`.

## Rotas

Públicas:
- `GET  /`                    vitrine
- `GET  /api/products`        lista produtos
- `GET  /api/products/:id`    detalhe

Auth:
- `POST /api/auth/login`      `{ username, password }`
- `POST /api/auth/logout`
- `GET  /api/auth/me`

Admin (sessão obrigatória):
- `POST   /api/products`        multipart: `name`, `description`, `price?`, `image`
- `PUT    /api/products/:id`    multipart, `image` opcional
- `DELETE /api/products/:id`    remove + apaga do Cloudinary

## Estrutura

```
.
├── server.js
├── models/Product.js
├── config/cloudinary.js
├── middleware/auth.js
├── public/
│   ├── index.html     # vitrine
│   ├── login.html
│   └── admin.html
├── scripts/
│   └── railway-setup.sh  # IaC: provisiona projeto + mongo + envs no Railway
├── Dockerfile
├── docker-compose.yml    # app + mongo para dev local
├── .dockerignore
├── .env / .env.example
├── Procfile
└── railway.json
```
