# frozen_string_literal: true

require "fileutils"

class MicroserviceGenerator
  def initialize(nome, stack)
    @nome = nome
    @stack = stack
  end

  def generate
    puts "🚀 Criando arquitetura de microserviços..."

    create_root
    create_services
    create_gateway
    create_shared
    create_infra
    create_docker_compose

    puts "✅ Arquitetura criada com sucesso!"
  end

  private

  def create_root
    FileUtils.mkdir_p(@nome)
  end

  def create_services
    %w[usuarios pedidos pagamentos].each do |service|
      path = "#{@nome}/services/#{service}"
      FileUtils.mkdir_p(path)

      create_service(path, service)
    end
  end

  def create_service(path, name)
    case @stack
    when "dotnet"
      system("dotnet new webapi -n #{name} -o #{path}")
    when "fastapi"
      File.write("#{path}/main.py", <<~PY)
        from fastapi import FastAPI

        app = FastAPI()

        @app.get("/")
        def health():
            return {"service": "#{name}", "status": "ok"}
      PY
    end

    create_env(path, name)
  end

  def create_env(path, name)
    File.write("#{path}/.env", <<~ENV)
      SERVICE_NAME=#{name}
      PORT=3000

      RABBITMQ_HOST=rabbitmq
      DATABASE_URL=
    ENV
  end

  def create_gateway
    path = "#{@nome}/gateway"
    FileUtils.mkdir_p(path)

    File.write("#{path}/README.md", "API Gateway")
  end

  def create_shared
    FileUtils.mkdir_p("#{@nome}/shared/contracts")
    FileUtils.mkdir_p("#{@nome}/shared/messaging")
  end

  def create_infra
    FileUtils.mkdir_p("#{@nome}/infra/rabbitmq")
    FileUtils.mkdir_p("#{@nome}/infra/mongo")
  end

  def create_docker_compose
    File.write("#{@nome}/docker-compose.yml", <<~YAML)
      version: '3.8'

      services:
        rabbitmq:
          image: rabbitmq:3-management
          ports:
            - "5672:5672"
            - "15672:15672"

        mongo:
          image: mongo
          ports:
            - "27017:27017"
        
        postgres:
          image: postgres:3.8
          ports:
            - "5432:5432"
          environment:
            -POSTGRES_PASSWORD: "123456"
    YAML
  end
end