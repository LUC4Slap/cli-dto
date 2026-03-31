# 🚀 DTO CLI

Uma ferramenta de linha de comando desenvolvida em **Ruby** para acelerar a criação de projetos **frontend e backend**, com suporte a múltiplas tecnologias e geração automática de estruturas arquiteturais (incluindo microserviços).

---

## 📦 Instalação

Clone o repositório:

```bash
git clone https://github.com/LUC4Slap/cli-dto
cd cli-dto
```

Instale as dependências:

```bash
bundle install
```

Execute diretamente:

```bash
./bin/dto-cli.rb
```

---

## ⚙️ Uso

### 🔹 Inicializar um projeto

```bash
./bin/dto-cli.rb init [TIPO] [STACK] [NOME] [OPÇÕES]
```

---

## 🧱 Parâmetros

| Parâmetro | Descrição                                         |
| --------- | ------------------------------------------------- |
| `TIPO`    | `frontend` ou `backend`                           |
| `STACK`   | Tecnologia (ex: `dotnet`, `fastapi`, `node`, etc) |
| `NOME`    | Nome do projeto                                   |

---

## 🧩 Opções

| Flag         | Descrição                                          |
| ------------ | -------------------------------------------------- |
| `--path`     | Caminho onde o projeto será criado                 |
| `--clean`    | Gera estrutura de arquitetura (microserviços)      |
| `--rabbitmq` | (Em desenvolvimento) Adiciona suporte a mensageria |

---

## 💻 Exemplos

### Backend .NET com Clean Architecture

```bash
./bin/dto-cli.rb init backend dotnet api \
  --clean \
  --path ../projetos
```

---

### Backend FastAPI com estrutura

```bash
./bin/dto-cli.rb init backend fastapi api \
  --clean
```

---

### Frontend React

```bash
./bin/dto-cli.rb init frontend react web-app
```

---

## 🏗️ Estrutura gerada (`--clean`)

```bash
projeto/
├── microservices/
│   └── api-exemplo/
├── services/
│   └── service-exemplo/
├── infra/
│   └── infra-exemplo/
├── common/
│   └── common-exemplo/
```

---

## 🧠 Tecnologias suportadas

### Backend

* .NET
* Node.js
* NestJS
* FastAPI
* Flask
* Rails

### Frontend

* Angular
* React
* Next.js
* Vue
* Nuxt

---

## 📁 Estrutura do CLI

```bash
cli-dto/
├── bin/
│   └── dto-cli.rb
├── lib/
│   ├── dto_cli.rb
│   ├── generators/
│   │   ├── backend_generator.rb
│   │   ├── frontend_generator.rb
│   ├── utils/
│   └── templates/
```

---

## 🧩 Templates

A pasta `templates/` permite criar **estruturas reutilizáveis** para projetos.

Exemplo:

```bash
templates/fastapi/clean/
```

Esses templates podem ser copiados diretamente para gerar projetos mais completos e padronizados.

---

## 🚀 Roadmap

* [ ] Suporte completo a RabbitMQ
* [ ] Templates avançados por stack
* [ ] Geração de código (controllers, services, etc.)
* [ ] Nomes dinâmicos baseados no projeto
* [ ] CLI instalável globalmente (`gem install`)
* [ ] Suporte a Docker / Docker Compose

---

## 🤝 Contribuição

Sinta-se livre para abrir PRs ou sugerir melhorias.

---

## 📄 Licença

MIT

---

## 👨‍💻 Autor

Desenvolvido por **Lucas Almeida**
