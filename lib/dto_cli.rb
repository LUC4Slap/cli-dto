require "thor"
require_relative "generator"
require "tty-prompt"
require_relative "generators/backend_generator"
require_relative "generators/frontend_generator"

class DtoCLI < Thor
  desc "gerar", "Gera DTO a partir de JSON"
  option :input, required: false
  option :url, required: false
  option :lang, required: true
  option :insecure, type: :boolean, default: false
  option :nome_classe, type: :string, default: "Root"
  option :tipo, type: :string, default: "interface", enum: ["interface", "class"]
  option :headers, type: :string, default: ""

  def gerar
    if options[:input].nil? && options[:url].nil?
      raise "Você deve informar --input ou --url"
    end

    generator = Generator.new(
      options[:input],
      options[:lang],
      options[:url],
      options[:insecure],
      options[:nome_classe],
      options[:tipo],
      options[:headers]
    )

    puts generator.generate
  end

  desc "version", "Mostra a versão da CLI"
  def version
    puts "dto-cli v0.1.0"
  end

  desc "init [TIPO] [STACK] [NOME]", "Inicializa projeto"

  option :path, type: :string, default: Dir.pwd
  option :clean, type: :boolean, default: false
  option :rabbitmq, type: :boolean, default: false

  def init(tipo = nil, stack = nil, nome = nil)
    prompt = TTY::Prompt.new

    tipo ||= prompt.select("Tipo do projeto:", %w[frontend backend])

    if tipo == "frontend"
      stack ||= prompt.select("Escolha o frontend:", %w[angular react next vue nuxt])
    else
      stack ||= prompt.select("Escolha o backend:", %w[dotnet node nest fastapi flask rails])
    end

    nome ||= prompt.ask("Nome do projeto?")

    path = options[:path]

    puts "\n📁 Criando em: #{path}/#{nome}"

    puts "⚙️ Clean Arch: #{options[:clean]}"
    puts "🐰 RabbitMQ: #{options[:rabbitmq]}"

    case tipo
    when "frontend"
      FrontendGenerator.new(stack, nome, path).generate
    when "backend"
      BackendGenerator.new(
        stack,
        nome,
        path,
        clean: options[:clean],
        rabbitmq: options[:rabbitmq]
      ).generate
    end
  end

  desc "init microservice NOME", "Cria arquitetura de microserviços"
  option :stack, default: "dotnet"
  def init_microservice(nome)
    MicroserviceGenerator.new(nome, options[:stack]).generate
  end
end