require "faraday"
require_relative "parsers/json_parser"
require_relative "generators/csharp_generator"
require_relative "generators/python_generator"
require_relative "generators/typescript_generator"
require "json"

class Generator
  def initialize(input, lang, url = nil, insecure = false, nome_classe = "Root", tipo = "interface", headers = {})
    @input = input
    @lang = lang
    @url = url
    @insecure = insecure
    @nome_classe = nome_classe
    @tipo = tipo
    @headers = parse_headers(headers)
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

    response = conn.get
    JSON.parse(response.body)
  end

  def parse_headers(headers)
    return {} unless headers

    JSON.parse(headers)
  rescue JSON::ParserError
    puts "❌ Headers inválidos. Use JSON válido."
    exit(1)
  end
end