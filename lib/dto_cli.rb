require "thor"
require_relative "generator"
require "tty-prompt"
require_relative "generators/backend_generator"
require_relative "generators/frontend_generator"
require 'byebug'
require 'colorized_string'
require_relative 'cores/cores'
require_relative 'db/data_base'
require_relative 'generators/controller_generator'

class DtoCLI < Thor
  def self.exit_on_failure?
    true
  end

  def initialize(args = nil, options = nil, config = nil)
    super
    @banco = Database.new
  end

  desc "gerar", "Gera DTO a partir de JSON"
  option :input, required: false
  option :url, required: false
  option :lang, required: true
  option :db, required: false
  option :insecure, type: :boolean, default: false
  option :nome_classe, type: :string, default: "Root"
  option :tipo, type: :string, default: "interface", enum: ["interface", "class"]
  option :headers, type: :string, default: ""
  option :query, type: :string, default: ""
  option :color, type: :string, default: "green", required: false

  def gerar
    if options[:input].nil? && options[:url].nil? && options[:db].nil?
      raise CliError, "Você deve informar --input ou --url ou --db"
    end

    if (!options[:headers].empty? || !options[:query].empty?) && options[:url].nil?
      raise CliError, "As options --headers e --query so poder ser passadas com a --url"
    end

    cores_permitidas = ColorizedString.colors
    color = (options[:color] || "green").to_sym
    color = cores_permitidas.include?(color) ? color : "green"

    generator = Generator.new(
      options[:input],
      options[:lang],
      options[:url],
      options[:insecure],
      options[:nome_classe],
      options[:tipo],
      options[:headers],
      options[:query],
      options[:db]
    )
    @banco.salvar_comando("gerar", options.to_s)
    puts generator.generate.send(color)
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
      @banco.salvar_comando("init frontend", options.to_s)
      FrontendGenerator.new(stack, nome, path).generate
    when "backend"
      @banco.salvar_comando("init backend", options.to_s)
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
    @banco.salvar_comando("init microservice", options.to_s)
    MicroserviceGenerator.new(nome, options[:stack]).generate
  end

  desc "color [verificar_color]","Cores possiveis"
  option :verificar_color, type: :string, required: false
  def color
    color = Cores.new(options[:verificar_color])
    if !options[:verificar_color].nil?
      @banco.salvar_comando("color", options.to_s)
      color.verificar_se_cor_existe
    else
      @banco.salvar_comando("color", options.to_s)
      color.cores_existentes
    end
  end

  desc "historico", "lista historico de comandos"
  option :query, type: :string, required: false
  def historico
    @banco.listar_comandos(options[:query]).map do |id, nome, comando, data|
      puts "nome: #{nome} - comando: #{comando} - criado_em: #{data}"
    end
  end

  desc "gerar_crud", "Gera Controller, Service e Repository a partir de JSON/DTO"
  option :input, required: false
  option :url, required: false
  option :lang, required: true
  option :path, type: :string, default: Dir.pwd
  option :color, type: :string, default: "green", required: false

  def gerar_crud
    if options[:input].nil? && options[:url].nil?
      raise CliError, "Você deve informar --input ou --url"
    end

    cores_permitidas = ColorizedString.colors
    color = (options[:color] || "green").to_sym
    color = cores_permitidas.include?(color) ? color : "green"

    json = if options[:input]
      JsonParser.parse(options[:input])
    elsif options[:url]
      require "faraday"
      response = Faraday.get(options[:url])
      JSON.parse(response.body)
    end

    generator = ControllerGenerator.new(json, lang: options[:lang], path: options[:path])
    @banco.salvar_comando("gerar_crud", options.to_s)
    puts generator.generate.send(color)
  end
end