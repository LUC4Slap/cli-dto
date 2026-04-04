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
# 🤖 Gerar DTO
```bash
dto-cli-dev.bat gerar --url https://jsonplaceholder.typicode.com/users --lang ts --insecure --nome_classe Historico --tipo class
```
Produzira o seguinte resultado:
```json
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
O resultado muda de acordo com a tecnologia passada, atualmente tendo 3 tipos que são

* [x] Typesctipt
* [x] Csharp
* [x] Python

## 🧱 Parâmetros

| Parâmetro | Descrição                                                                                           |
| --------- |-----------------------------------------------------------------------------------------------------|
| `--url`    | Url do json                                                                                         |
| `--lang`   | Tecnologia (ex: `ts`, `cs`, `py`)                                                                   |
| `--insecure`    | Para não dar problema com o certificado ssl                                                         |
|`--nome_classe` | Para nome da classe final                                                                           |
| `--tipo` | Para definir o tipo de entre `interface` ou `class` somente para a tecnologia TypeScript atualmente |
|`--input` | Caminho do arquivo json que deseja, caso não queira utilizar a requisição http do parametro url     |
 | `--db` | Caminho de um aquivo `.sql` para gerar o `dto`                                                      |
| `--color` | Cor para retorno do `dto`                                                                           |
 | `--headers` | Headers a serem passados quando o `dto` for utilizado com a opção `--url` |
| `--query` | Query Params a serem utilizado quando o `dto` for utilizado com a opção `--url` |


---
## Instalar a gem
```bash
# Desinstalar caso esteja instalado
gem uninstall dto-cli

# Buildar a gem
gem build dto-cli.gemspec

# Instalar a gem
gem install ./dto-cli-0.1.0.gem
```
---
# Histórico
É gerado um banco de dados sqlite na raiz do projeto para salvar os comando utilizados para historico
```bash
./bin/dto-cli-dev historico
```
Vai devolver uma resposta assim:
```txt
nome: gerar - comando: {"insecure"=>false, "nome_classe"=>"Usuario", "tipo"=>"interface", "headers"=>"", "query"=>"", "color"=>"cyan", "db"=>"../test-cli/schema.sql", "lang"=>"cs"} - criado_em: 2026-04-04 20:37:27
nome: color - comando: {} - criado_em: 2026-04-04 20:37:35
nome: gerar - comando: {"insecure"=>false, "nome_classe"=>"Usuario", "tipo"=>"interface", "headers"=>"", "query"=>"", "color"=>"cyan", "db"=>"../test-cli/schema.sql", "lang"=>"cs"} - criado_em: 2026-04-04 20:45:36
nome: gerar - comando: {"insecure"=>false, "nome_classe"=>"Usuario", "tipo"=>"interface", "headers"=>"", "query"=>"", "color"=>"cyan", "db"=>"../test-cli/schema.sql", "lang"=>"ts"} - criado_em: 2026-04-04 20:45:45
```
|parametro | Descrição|
|--------- | ---------|
| `--query`| query de busca no banco, a clausula where é colocada automaticamente, tem que mandar somente a condição de busca |

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
