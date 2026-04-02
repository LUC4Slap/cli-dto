require "faraday"
require_relative "parsers/json_parser"
require_relative "generators/csharp_generator"
require_relative "generators/python_generator"
require_relative "generators/typescript_generator"
require "json"
require "byebug"

class Generator
  def initialize(input, lang, url = nil, insecure = false, nome_classe = "Root", tipo = "interface", headers = {}, query = {}, db = nil)
    @input = input
    @lang = lang
    @url = url
    @insecure = insecure
    @nome_classe = nome_classe
    @tipo = tipo
    @headers = parse_headers(headers)
    @query = parse_query(query)
    @db = db
  end

  def generate
    if @url
      json = fetch_from_url
    elsif @input
      json = JsonParser.parse(@input)
    elsif @db
      json = processar_sql
    else
      raise "Error informe um parametro"
    end

    json = json.is_a?(String) ? JSON.parse(json) : json

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

  def processar_sql
    sql = File.read(@db)
    sql = sql.gsub(/--.*$/, '')

    tables = sql.scan(/CREATE TABLE.*?;/m)
    # debugger
    if tables.nil? || tables.empty?
      raise "O sql tem que ser da criação da tabela"
    end

    tables.each do |table|
      table_name = table.match(/CREATE TABLE\s+"?(\w+)"?/i)[1]

      colunas_str = table.match(/\((.*)\)/m)[1]

      colunas = colunas_str.split(",\n").map(&:strip)

      colunas = colunas.reject do |c|
        c.upcase.start_with?("PRIMARY", "FOREIGN", "UNIQUE")
      end
      json = parse_columns(colunas)

      puts "Tabela: #{table_name}"
      return JSON.pretty_generate(json)
    end
  end

  def parse_columns(colunas)
    result = {}

    colunas.each do |col|
      partes = col.strip.split(/\s+/)

      nome = partes[0].gsub('"', '')
      tipo_sql = partes[1]

      result[nome] = map_sql_type(tipo_sql)
    end

    result
  end

  def map_sql_type(sql_type)
    case sql_type.downcase
    when "text"
      "string"
    when "uuid"
      "string"
    when "int", "integer"
      "int"
    when "bigint"
      "long"
    when "boolean"
      "bool"
    when "timestamp", "timestamp(3)"
      "DateTime"
    else
      "object"
    end
  end
end