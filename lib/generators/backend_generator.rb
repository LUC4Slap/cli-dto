# frozen_string_literal: true
# frozen_string_literal: true
require_relative "../utils/env_generator"
require_relative "docker_generator"
require "fileutils"

class BackendGenerator
  def initialize(stack, nome, path, clean: false, rabbitmq: false, docker: false)
    @stack = stack
    @nome = nome
    @path = path
    @clean = clean
    @rabbitmq = rabbitmq
    @docker = docker
  end

  def generate
    full_path = File.join(@path, @nome)

    case @stack
    when "dotnet"
      generate_dotnet(full_path)

    when "fastapi"
      generate_fastapi(full_path)

    when "node"
      generate_node(full_path)

    when "nest"
      generate_nest(full_path)

    when "flask"
      generate_flask(full_path)

    when "rails"
      generate_rails(full_path)

    else
      puts "Stack não suportada"
    end

    if @docker
      generate_docker_files(full_path)
    end

    puts "✅ Projeto criado em #{full_path}"
  end

  private

  # =========================
  # 🧱 ESTRUTURA PADRÃO
  # =========================

  def create_clean_structure(base)
    paths = {
      microservices: File.join(base, "microservices/api-exemplo"),
      services:      File.join(base, "services/service-exemplo"),
      infra:         File.join(base, "infra/infra-exemplo"),
      common:        File.join(base, "common/common-exemplo")
    }

    paths.each_value do |path|
      FileUtils.mkdir_p(path)
    end

    paths
  end

  # =========================
  # 🔵 DOTNET
  # =========================

  def generate_dotnet(base)
    if @clean
      puts "🏗️ Aplicando Clean Architecture..."

      paths = create_clean_structure(base)

      run("dotnet new webapi -n ApiExemplo -o #{paths[:microservices]}")
      run("dotnet new classlib -n ServiceExemplo -o #{paths[:services]}")
      run("dotnet new classlib -n InfraExemplo -o #{paths[:infra]}")
      run("dotnet new classlib -n CommonExemplo -o #{paths[:common]}")

      Dir.chdir(base) do
        run("dotnet new sln -n #{@nome}")

        Dir.glob("**/*.csproj").each do |proj|
          run("dotnet sln add #{proj}")
        end

        run("dotnet add microservices/api-exemplo/ApiExemplo.csproj reference services/service-exemplo/ServiceExemplo.csproj")

        run("dotnet add services/service-exemplo/ServiceExemplo.csproj reference infra/infra-exemplo/InfraExemplo.csproj")

        run("dotnet add services/service-exemplo/ServiceExemplo.csproj reference common/common-exemplo/CommonExemplo.csproj")
      end

      puts "✅ Estrutura Clean criada"
    else
      run("dotnet new webapi -n #{@nome} -o #{base}")
    end

    puts "🐰 RabbitMQ: #{@rabbitmq}" if @rabbitmq
  end

  # =========================
  # 🟢 FASTAPI
  # =========================

  def generate_fastapi(base)
    if @clean
      puts "🏗️ Criando estrutura FastAPI..."

      paths = create_clean_structure(base)

      File.write("#{paths[:microservices]}/main.py", <<~PY)
        from fastapi import FastAPI

        app = FastAPI()

        @app.get("/")
        def root():
            return {"service": "api-exemplo"}
      PY

      File.write("#{paths[:services]}/service.py", <<~PY)
        class ServiceExemplo:
            def executar(self):
                return "ok"
      PY

      File.write("#{paths[:infra]}/db.py", <<~PY)
        def connect():
            return "db connection"
      PY

      File.write("#{paths[:common]}/utils.py", <<~PY)
        def helper():
            return "helper"
      PY

      puts "✅ Estrutura FastAPI criada"
    else
      criar_fastapi(base)
    end
  end

  # =========================
  # 🟡 NODE
  # =========================

  def generate_node(base)
    if @clean
      puts "🏗️ Criando estrutura Node..."

      paths = create_clean_structure(base)

      run("cd #{base} && npm init -y")

      File.write("#{paths[:microservices]}/app.js", <<~JS)
        const express = require("express");
        const app = express();

        app.get("/", (req, res) => res.json({ service: "api-exemplo" }));

        app.listen(3000);
      JS

      puts "✅ Node estruturado"
    else
      FileUtils.mkdir_p(base)
      run("cd #{base} && npm init -y")
    end
  end

  # =========================
  # 🟣 NEST
  # =========================

  def generate_nest(base)
    if @clean
      puts "🏗️ Criando estrutura Nest..."

      paths = create_clean_structure(base)

      run("npx @nestjs/cli new api-exemplo --directory #{paths[:microservices]}")

      puts "✅ Nest estruturado"
    else
      run("npx @nestjs/cli new #{@nome} --directory #{base}")
    end
  end

  # =========================
  # 🔴 FLASK
  # =========================

  def generate_flask(base)
    if @clean
      puts "🏗️ Criando estrutura Flask..."

      paths = create_clean_structure(base)

      File.write("#{paths[:microservices]}/app.py", <<~PY)
        from flask import Flask

        app = Flask(__name__)

        @app.route("/")
        def home():
            return {"service": "api-exemplo"}
      PY

      puts "✅ Flask estruturado"
    else
      criar_flask(base)
    end
  end

  # =========================
  # 🟠 RAILS
  # =========================

  def generate_rails(base)
    if @clean
      puts "🏗️ Criando estrutura Rails..."

      paths = create_clean_structure(base)

      run("rails new #{paths[:microservices]}")

      puts "✅ Rails estruturado"
    else
      run("rails new #{base}")
    end
  end

  # =========================
  # 🔧 HELPERS
  # =========================

  def run(cmd)
    puts "🚀 #{cmd}"
    system(cmd)
  end

  def criar_fastapi(path)
    FileUtils.mkdir_p(path)

    File.write("#{path}/main.py", <<~PY)
      from fastapi import FastAPI

      app = FastAPI()

      @app.get("/")
      def health():
          return {"status": "ok"}
    PY
  end

  def criar_flask(path)
    FileUtils.mkdir_p(path)

    File.write("#{path}/app.py", <<~PY)
      from flask import Flask

      app = Flask(__name__)

      @app.route("/")
      def home():
          return {"status": "ok"}
    PY
  end

  # =========================
  # 🐳 DOCKER
  # =========================

  def generate_docker_files(base)
    docker_map = {
      "dotnet" => "dotnet",
      "node" => "node",
      "nest" => "nest",
      "fastapi" => "fastapi",
      "flask" => "flask",
      "rails" => "rails"
    }

    stack = docker_map[@stack]
    return puts "  Stack #{@stack} nao tem Dockerfile automatico (por enquanto)" unless stack

    generator = DockerGenerator.new(
      path: base,
      stack: stack,
      services: %w[api postgres],
      name: @nome,
      output: "docker-compose.yml"
    )
    generator.generate_both
    puts "  Dockerfile e docker-compose.yml criados"
  end
end
