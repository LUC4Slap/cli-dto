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
require_relative 'generators/docker_generator'
require_relative 'youtubers/you_tubers'

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
  option :docker, type: :boolean, default: false

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
        rabbitmq: options[:rabbitmq],
        docker: options[:docker]
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

  desc "docker [TIPO]", "Gera Dockerfile e/ou docker-compose.yml automaticamente"
  option :stack, type: :string, required: false
  option :services, type: :string, required: false
  option :path, type: :string, default: Dir.pwd
  option :name, type: :string, default: "app"
  option :output, type: :string, default: "docker-compose.yml"
  option :dockerfile_only, type: :boolean, default: false
  option :compose_only, type: :boolean, default: false
  option :color, type: :string, default: "green", required: false

  def docker(tipo = nil)
    cores_permitidas = ColorizedString.colors
    color = (options[:color] || "green").to_sym
    color = cores_permitidas.include?(color) ? color : "green"

    services = options[:services] ? options[:services].split(",") : []

    generator = DockerGenerator.new(
      path: options[:path],
      stack: options[:stack],
      services: services,
      name: options[:name],
      output: options[:output]
    )

    result = if options[:dockerfile_only]
      generator.generate_dockerfile
    elsif options[:compose_only]
      generator.generate_compose
    else
      generator.generate_both
    end

    @banco.salvar_comando("docker", options.to_s)
    puts result.send(color)
  end

  desc "youtube", "Interage com videos do YouTube (videos, comentarios, respostas)"
  option :key, type: :string, required: true
  option :perfil_id, type: :string, required: false
  option :video_id, type: :string, required: false
  option :comentarios, type: :boolean, default: false
  option :responder, type: :string, default: nil
  option :parent_id, type: :string, default: nil
  option :obter_id_canal, type: :string, default: nil, required: false
  option :color, type: :string, default: "green", required: false

  def youtube
    yt = YouTubers.new(options[:perfil_id], options[:color], options[:video_id], options[:key], options[:obter_id_canal])
    @banco.salvar_comando("youtube", options.to_s)
    cor = options[:color]
    if cor.nil?
      cor = 'green'
    end
    if !options[:responder].nil?
      yt.responder_comentario(options[:responder], options[:parent_id])
    elsif options[:comentarios] || options[:video_id]
      raise CliError, "--video-id é obrigatório para ver comentários" unless options[:video_id]

      comments = yt.retornar_comentarios
      if comments.empty?
        puts "Nenhum comentário encontrado.".send(cor.to_sym)
      else
        comments.each_with_index do |c, i|
          puts "#{i + 1}. #{c[:author]}: #{c[:text]}".send(cor.to_sym)
        end
      end
    elsif options[:perfil_id]
      videos = yt.retornar_videos
      if videos.empty?
        puts "Nenhum vídeo encontrado.".send(cor.to_sym)
      else
        videos.each do |v|
          puts "#{v[:title]}".send(cor.to_sym)
          puts "   ID: #{v[:video_id]} | Publicado em: #{v[:published_at]}"
        end
      end
    elsif options[:obter_id_canal]
      yt.obter_id_canal.map do |item|
        puts item['id']['channelId'].send(cor.to_sym)
      end
    else
      raise CliError, "Informe --perfil-id (vídeos) ou --video-id (comentários) ou --responder (responder comentário)"
    end
  end
end