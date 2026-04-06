# DTO CLI

Ferramenta de linha de comando em **Ruby** para gerar DTOs a partir de JSON/SQL e scaffold projetos frontend/backend com suporte a Clean Architecture e microservicos.

---

## Índice

- [Instalação](#instalacao)
- [Comandos disponíveis](#comandos-disponiveis)
  - [gerar](#-gerar-dto)
  - [gerar_crud](#-gerar-crud---controller--service--repository)
  - [init](#-inicializar-projeto)
  - [init microservice](#-arquitetura-de-microservicos)
  - [color](#-cores)
  - [historico](#-historico-de-comandos)
  - [version](#-versao)
- [Tecnologias suportadas](#tecnologias-suportadas)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Roadmap](#roadmap)
- [Contribuição](#contribuicao)
- [Licença](#licenca)

---

## Instalacao

### Via Gem (recomendado)

```bash
git clone https://github.com/LUC4Slap/cli-dto
cd cli-dto
bundle install
gem build dto-cli.gemspec
gem install ./dto-cli-0.1.0.gem
```

Após instalar, use o comando globalmente:

```bash
dto-cli-dev gerar --url https://jsonplaceholder.typicode.com/users --lang ts --nome_classe Usuario
```

### Via repositório

```bash
git clone https://github.com/LUC4Slap/cli-dto
cd cli-dto
bundle install
./bin/dto-cli-dev
```

### Dependências

| Gem        | Uso                                       |
| ---------- | ----------------------------------------- |
| `thor`     | Framework CLI                             |
| `faraday`  | Requisições HTTP                          |
| `activesupport` | Inflector e utilitários              |
| `colorize` | Output colorido no terminal               |
| `tty-prompt` | Prompts interativos                    |
| `sqlite3`  | Persistência do histórico de comandos     |

---

## Comandos disponíveis

```bash
dto-cli-dev <comando> [argumentos] [opcoes]
```

Use `dto-cli-dev help` para ver todos os comandos.

### `gerar` — DTO

Gera DTOs a partir de uma URL JSON, arquivo local ou schema SQL.

```bash
dto-cli-dev gerar --url <URL> --lang <LINGUAGEM> [opcoes]
dto-cli-dev gerar --input <ARQUIVO> --lang <LINGUAGEM> [opcoes]
dto-cli-dev gerar --db <ARQUIVO.SQL> --lang <LINGUAGEM> [opcoes]
```

**Opções:**

| Flag              | Padrão       | Descrição                                                            |
| ----------------- | ------------ | -------------------------------------------------------------------- |
| `--url`           | —            | URL do JSON para gerar o DTO                                         |
| `--input`         | —            | Caminho para arquivo JSON local                                      |
| `--db`            | —            | Caminho para arquivo `.sql` para gerar o DTO                         |
| `--lang` **(req)**| —            | Linguagem de saída: `ts`, `cs`, `py`                                 |
| `--nome_classe`   | `Root`       | Nome da classe final                                                 |
| `--tipo`          | `interface`  | Tipo de saída para TypeScript: `interface` ou `class`                |
| `--insecure`      | `false`      | Ignora validação de certificado SSL                                  |
| `--headers`       | —            | Headers customizados para requisição (requer `--url`)                |
| `--query`         | —            | Query params para requisição (requer `--url`)                        |
| `--color`         | `green`      | Cor do output no terminal                                            |

**Exemplo:**

```bash
dto-cli-dev gerar \
  --url https://jsonplaceholder.typicode.com/users \
  --lang ts \
  --insecure \
  --nome_classe Historico \
  --tipo class \
  --color cyan
```

**Saída (TypeScript com `--tipo class`):**

```typescript
export class Geo {
    lat: string;
    lng: string;
}

export class Address {
    street: string;
    suite: string;
    city: string;
    zipcode: string;
    geo: Geo;
}

export class Company {
    name: string;
    catchPhrase: string;
    bs: string;
}

export class Item {
    id: number;
    name: string;
    username: string;
    email: string;
    address: Address;
    phone: string;
    website: string;
    company: Company;
}

export class Historico {
    items: Array<Item>;
}
```

**Linguagens suportadas para geração de DTO:**

| Flag `--lang` | Linguagem    |
| ------------- | ------------ |
| `ts`          | TypeScript   |
| `cs`          | C#           |
| `py`          | Python       |

---

### `gerar_crud` — Controller, Service & Repository

Gera Controllers, Services e Repositories a partir de um JSON/DTO automaticamente. Cada entidade detectada gera 3 arquivos com endpoints REST completos (GET, GET/:id, POST, PUT, DELETE).

```bash
dto-cli-dev gerar_crud --input <ARQUIVO>.json --lang <LINGUAGEM> [opcoes]
dto-cli-dev gerar_crud --url <URL> --lang <LINGUAGEM> [opcoes]
```

**Opções:**

| Flag              | Padrão       | Descrição                                                            |
| ----------------- | ------------ | -------------------------------------------------------------------- |
| `--url`           | —            | URL do JSON para gerar o CRUD                                        |
| `--input`         | —            | Caminho para arquivo JSON local                                      |
| `--lang` **(req)**| —            | Linguagem: `dotnet`, `node`, `python`, `typescript`                  |
| `--path`          | `Dir.pwd`    | Diretorio de saida dos arquivos                                      |
| `--color`         | `green`      | Cor do output no terminal                                            |

**Exemplo:**

```bash
dto-cli-dev gerar_crud \
  --input user.json \
  --lang dotnet \
  --path ./src
```

**Saída:**

```
Controllers gerados:
  - UserController.cs
  - AddressController.cs

Services gerados:
  - UserService.cs
  - AddressService.cs

Repositories gerados:
  - UserRepository.cs
  - AddressRepository.cs

Total: 2 controllers, 2 services, 2 repositories gerados com sucesso!
```

**Linguagens suportadas para geração de CRUD:**

| Flag `--lang`      | Linguagem        | Estilo                           |
| ------------------ | ---------------- | -------------------------------- |
| `dotnet`/`cs`      | C# / .NET        | `[ApiController]`, interfaces   |
| `node`/`js`        | Node.js          | Express + `module.exports`       |
| `python`/`py`      | Python           | FastAPI + routers                |
| `typescript`/`ts`  | TypeScript       | Express com types                |

---

### `init` — Inicializar projeto

Cria um projeto frontend ou backend com scaffolding automático.

```bash
dto-cli-dev init [TIPO] [STACK] [NOME] [opcoes]
```

Se omitidos, `TIPO`, `STACK` e `NOME` são solicitados interativamente.

**Argumentos posicionais:**

| Posição | Descrição                                     |
| ------- | --------------------------------------------- |
| `TIPO`  | `frontend` ou `backend`                       |
| `STACK` | Tecnologia (ex: `dotnet`, `fastapi`, `react`) |
| `NOME`  | Nome do projeto                               |

**Opções:**

| Flag         | Padrão    | Descrição                                              |
| ------------ | --------- | ------------------------------------------------------ |
| `--path`     | `Dir.pwd`| Caminho onde o projeto será criado                     |
| `--clean`    | `false`   | Gera estrutura Clean Architecture com microservicos    |
| `--rabbitmq` | `false`   | Adiciona suporte a mensageria RabbitMQ                 |

**Exemplos:**

```bash
# Backend .NET com Clean Architecture
dto-cli-dev init backend dotnet minha-api --clean --path ../projetos

# Backend FastAPI
dto-cli-dev init backend fastapi minha-api --clean

# Frontend React
dto-cli-dev init frontend react web-app

# Modo interativo (sem argumentos)
dto-cli-dev init
```

---

### `init microservice` — Arquitetura de microservicos

Cria uma estrutura de microservicos.

```bash
dto-cli-dev init microservice <NOME> --stack <STACK>
```

**Opções:**

| Flag     | Padrão   | Descrição                |
| -------- | -------- | ------------------------ |
| `--stack`| `dotnet` | Tecnologia do microserviço |

**Exemplo:**

```bash
dto-cli-dev init microservice servico-pagamento --stack dotnet
```

---

### `color` — Cores

Lista as cores disponíveis ou verifica se uma cor existe.

```bash
# Listar todas as cores disponíveis
dto-cli-dev color

# Verificar se uma cor específica existe
dto-cli-dev color --verificar-color red
```

---

### `historico` — Histórico de comandos

Lista os comandos executados anteriormente, salvos em um banco SQLite (`comandos.db`).

```bash
dto-cli-dev historico [opcoes]
```

**Opções:**

| Flag      | Descrição                                              |
| --------- | ------------------------------------------------------ |
| `--query` | Filtro SQL para a cláusula WHERE (sem o `WHERE`)       |

**Exemplos:**

```bash
# Listar todo o histórico
dto-cli-dev historico

# Filtrar por tipo de comando
dto-cli-dev historico --query "nome LIKE '%gerar%'"

# Filtrar por data
dto-cli-dev historico --query "criado_em > '2026-04-04 20:00:00'"
```

**Saída:**

```
nome: gerar - comando: {"insecure"=>false, "nome_classe"=>"Usuario", "lang"=>"cs", ...} - criado_em: 2026-04-04 20:37:27
nome: color - comando: {} - criado_em: 2026-04-04 20:37:35
nome: gerar - comando: {"insecure"=>false, "nome_classe"=>"Usuario", "lang"=>"ts", ...} - criado_em: 2026-04-04 20:45:45
```

---

### `version` — Versão

Exibe a versão instalada do CLI.

```bash
dto-cli-dev version
```

---

## Tecnologias suportadas

### Backend (comando `init`)

| Stack    | Framework          |
| -------- | ------------------ |
| `dotnet` | .NET               |
| `node`   | Node.js            |
| `nest`   | NestJS             |
| `fastapi`| FastAPI (Python)   |
| `flask`  | Flask (Python)     |
| `rails`  | Ruby on Rails      |

### Frontend (comando `init`)

| Stack    | Framework     |
| -------- | ------------- |
| `angular`| Angular       |
| `react`  | React         |
| `next`   | Next.js       |
| `vue`    | Vue.js        |
| `nuxt`   | Nuxt.js       |

---

## Estrutura do projeto

```
cli-dto/
├── bin/
│   └── dto-cli-dev                 # Ponto de entrada do CLI
├── lib/
│   ├── dto_cli.rb                  # Classe principal Thor com os comandos
│   ├── generator.rb                # Gerador genérico de DTO
│   ├── generators/
│   │   ├── backend_generator.rb    # Scaffold de projetos backend
│   │   ├── frontend_generator.rb   # Scaffold de projetos frontend
│   │   ├── microservice_generator.rb # Estrutura de microservicos
│   │   ├── controller_generator.rb # Gera Controller, Service e Repository
│   │   ├── typescript_generator.rb # Gerador DTO TypeScript
│   │   ├── csharp_generator.rb     # Gerador DTO C#
│   │   └── python_generator.rb     # Gerador DTO Python
│   ├── parsers/
│   │   └── json_parser.rb          # Parser e inferência de tipos
│   ├── db/
│   │   └── data_base.rb            # Persistência SQLite do histórico
│   ├── utils/
│   │   └── env_generator.rb        # Geração de variáveis de ambiente
│   ├── cores/
│   │   └── cores.rb                | Validação e listagem de cores
│   └── error/
│       └── cli_error.rb            # Tratamento customizado de erros
├── Gemfile
├── dto-cli.gemspec
└── comandos.db                     # Banco SQLite do histórico
```

---

## Roadmap

- [ ] Templates avançados por stack
- [x] Geração de código (controllers, services, etc.)
- [ ] Suporte a Docker / Docker Compose
- [ ] Gerar DTO para outras linguagens (Go, Java, Rust, etc.)
- [ ] Validação de schemas gerados
- [ ] Testes automatizados

---

## Contribuicao

Sinta-se livre para abrir PRs ou sugerir melhorias.

---

## Licenca

MIT

---

## Autor

Desenvolvido por **Lucas Almeida**
