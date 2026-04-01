require "faraday"
require_relative "parsers/json_parser"
require_relative "generators/csharp_generator"
require_relative "generators/python_generator"
require_relative "generators/typescript_generator"
require "json"

class Generator
  def initialize(input, lang, url = nil, insecure = false, nome_classe = "Root", tipo = "interface", headers = {}, query = {})
    @input = input
    @lang = lang
    @url = url
    @insecure = insecure
    @nome_classe = nome_classe
    @tipo = tipo
    @headers = parse_headers(headers)
    @query = parse_query(query)
  end

  def generate
    json = @url ? fetch_from_url : JsonParser.parse(@input)
    # puts json

    case @lang
    when "cs"
      CSharpGenerator.new(json).generate
    when "py"
      PythonGenerator.new(json).generate
    when "ts"
      TypeScriptGenerator.new(json, @nome_classe, @tipo).generate
    else
      raise "Linguagem não suportada"
    end
  end

  private

  def fetch_from_url
    conn = Faraday.new(
      url: @url,
      ssl: { verify: !@insecure },
      headers: @headers,
    )

    response = conn.get do |req|
      req.params = @query
    end

    if response.body.nil? || response.body.strip.empty?
      puts "❌ Resposta vazia da API (status #{response.status})"
      exit(1)
    end

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      puts "❌ Resposta não é JSON válido:"
      puts response.body
      exit(1)
    end
  end

  def parse_headers(headers)
    return {} if headers.nil? || headers.empty?

    # 👉 tenta JSON primeiro
    begin
      return JSON.parse(headers)
    rescue JSON::ParserError
      # continua
    end

    # 👉 fallback: formato "key: value"
    headers.split(",").each_with_object({}) do |pair, acc|
      key, value = pair.split(":", 2)

      if key && value
        acc[key.strip] = value.strip
      else
        puts "❌ Header inválido: #{pair}"
        exit(1)
      end
    end
  end

  def parse_query(query)
    return {} if query.nil? || query.empty?

    # tenta JSON
    begin
      return JSON.parse(query)
    rescue JSON::ParserError
    end

    # fallback: "id: 15, nome: teste"
    query.split(",").each_with_object({}) do |pair, acc|
      key, value = pair.split(":", 2)

      if key && value
        acc[key.strip] = value.strip
      else
        puts "❌ Query inválida: #{pair}"
        exit(1)
      end
    end
  end
end