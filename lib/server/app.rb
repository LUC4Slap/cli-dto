require "sinatra"
require "json"
require_relative "../generators/controller_generator"
require_relative "../generators/docker_generator"
require_relative "../generators/go_generator"
require_relative "../generators/java_generator"
require_relative "../generators/kotlin_generator"
require_relative "../generators/rust_generator"
require_relative "../generators/swift_generator"
require_relative "../generators/csharp_generator"
require_relative "../generators/python_generator"
require_relative "../generators/typescript_generator"
require_relative "../parsers/json_parser"
require_relative "../db/data_base"

set :port, ENV.fetch("PORT", 4567)
set :bind, "0.0.0.0"
set :public_folder, File.expand_path("public", __dir__)

set :db, Database.new

# ============================================
# API Routes
# ============================================

post "/api/dto" do
  content_type :json

  body = JSON.parse(request.body.read)
  json_payload = body["json"]
  lang = body["lang"]
  nome = body["nome"] || "Root"
  tipo = body["tipo"] || "interface"
  nome_salvo = body["nome_salvo"] || nil

  raise "json e lang sao obrigatorios" unless json_payload && lang

  generator = case lang
              when "ts" then TypeScriptGenerator.new(json_payload, nome, tipo)
              when "cs" then CSharpGenerator.new(json_payload)
              when "py" then PythonGenerator.new(json_payload)
              when "go" then GoGenerator.new(json_payload, nome)
              when "java" then JavaGenerator.new(json_payload, nome)
              when "kotlin" then KotlinGenerator.new(json_payload, nome)
              when "swift" then SwiftGenerator.new(json_payload, nome)
              when "rust" then RustGenerator.new(json_payload, nome)
              else halt 400, { erro: "lang nao suportada" }.to_json
              end

  codigo = generator.generate

  if nome_salvo
    settings.db.salvar_dto(nome_salvo, lang, tipo, json_payload.to_json, codigo)
  end

  { codigo: codigo }.to_json
end

post "/api/crud" do
  content_type :json

  body = JSON.parse(request.body.read)
  json_payload = body["json"]
  lang = body["lang"]
  path = body["path"] || "."

  raise "json e lang sao obrigatorios" unless json_payload && lang

  generator = ControllerGenerator.new(json_payload, lang: lang, path: path)
  output = generator.generate

  { output: output }.to_json
end

post "/api/docker" do
  content_type :json

  body = JSON.parse(request.body.read)
  path = body["path"] || "."
  stack = body["stack"]
  services = body["services"] || []
  name = body["name"] || "app"
  return_only = body["return_only"] || false

  generator = DockerGenerator.new(
    path: path,
    stack: stack,
    services: services,
    name: name,
    output: body["output"] || "docker-compose.yml",
    return_only: return_only
  )

  if stack && !services.empty?
    result = generator.generate_both
    { dockerfile: return_only ? generator.dockerfile_content : nil, compose: return_only ? generator.compose_content : nil, output: result }.to_json
  elsif stack
    result = generator.generate_dockerfile
    { dockerfile: return_only ? generator.dockerfile_content : nil, output: result }.to_json
  elsif !services.empty?
    result = generator.generate_compose
    { compose: return_only ? generator.compose_content : nil, output: result }.to_json
  else
    halt 400, { erro: "informe stack e/ou services" }.to_json
  end
end

get "/api/dtos" do
  content_type :json
  busca = params["busca"]
  dtos = settings.db.listar_dtos(busca)
  dtos.to_json
rescue
  [].to_json
end

get "/api/dtos/:id" do
  content_type :json
  dto = settings.db.buscar_dto(params[:id])
  halt 404, { erro: "dto nao encontrado" }.to_json unless dto
  dto.to_json
end

delete "/api/dtos/:id" do
  content_type :json
  settings.db.deletar_dto(params[:id])
  { ok: true }.to_json
end

post "/api/dtos" do
  content_type :json
  body = JSON.parse(request.body.read)
  settings.db.salvar_dto(
    body["nome"],
    body["lang"],
    body["tipo"],
    body["json_payload"] || "",
    body["codigo"] || ""
  )
  { ok: true }.to_json
end

# ============================================
# Dashboard Routes (Web UI)
# ============================================

set :views, File.expand_path("views", __dir__)

helpers do
  def e(text)
    Rack::Utils.escape_html(text.to_s)
  end
end

get "/" do
  @stats = settings.db.estatisticas
  erb :index
end

get "/historico" do
  @dtos = settings.db.listar_dtos
  erb :historico
end

get "/dto/novo" do
  erb :novo_dto
end

get "/dto/:id" do |id|
  @dto = settings.db.buscar_dto(id)
  halt 404, "DTO nao encontrado" unless @dto
  erb :ver_dto
end

delete "/dto/:id" do
  settings.db.deletar_dto(params[:id])
  redirect "/"
end

post "/dto/delete/:id" do
  settings.db.deletar_dto(params[:id])
  redirect "/"
end

post "/docker/gerar" do
  @servicos = params["services"]
  @stack_docker = params["stack"]
  @nome = params["nome"] || "app"

  if @servicos.to_s.empty?
    @erro = "Informe pelo menos um servico"
    erb :novo_dto
    return
  end

  services = @servicos.split(",").map(&:strip)

  generator = DockerGenerator.new(
    path: ".",
    stack: @stack_docker.empty? ? nil : @stack_docker,
    services: services,
    name: @nome,
    return_only: true
  )

  begin
    if @stack_docker && !@stack_docker.empty?
      @dockerfile_content = generator.dockerfile_content
      @compose_content = generator.compose_content
      @codigo = "# docker-compose.yml\n\n" + @compose_content
      if @dockerfile_content
        @codigo = "# Dockerfile\n\n" + @dockerfile_content + "\n" + @codigo
      end
    else
      @dockerfile_content = nil
      @compose_content = generator.compose_content
      @codigo = @compose_content
    end
  rescue => e
    @erro = e.message
    erb :novo_dto
    return
  end

  @dto = { nome: @nome, lang: "docker-compose", tipo: "infra", json_payload: "", codigo: @codigo, criado_em: Time.now.to_s }
  settings.db.salvar_dto(@nome, "docker-compose", "infra", "", @codigo)

  erb :ver_dto
end

post "/dto/gerar" do
  json_str = params["json_payload"]
  lang = params["lang"]
  nome = params["nome"] || "Root"
  tipo = params["tipo"] || "interface"
  nome_salvo = params["nome_salvo"]

  begin
    json_payload = JSON.parse(json_str)
  rescue JSON::ParserError
    @erro = "JSON invalido"
    erb :novo_dto
    return
  end

  generator = case lang
              when "ts" then TypeScriptGenerator.new(json_payload, nome, tipo)
              when "cs" then CSharpGenerator.new(json_payload)
              when "py" then PythonGenerator.new(json_payload)
              when "go" then GoGenerator.new(json_payload, nome)
              when "java" then JavaGenerator.new(json_payload, nome)
              when "kotlin" then KotlinGenerator.new(json_payload, nome)
              when "swift" then SwiftGenerator.new(json_payload, nome)
              when "rust" then RustGenerator.new(json_payload, nome)
              else
                @erro = "Linguagem nao suportada"
                erb :novo_dto
                return
              end

  begin
    @codigo = generator.generate
  rescue => e
    @erro = e.message
    erb :novo_dto
    return
  end

  @dto = { nome: nome_salvo || nome, lang: lang, tipo: tipo, json_payload: json_str, codigo: @codigo, criado_em: Time.now.to_s }

  if nome_salvo
    settings.db.salvar_dto(nome_salvo, lang, tipo, json_str, @codigo)
  end

  erb :ver_dto
end
