require "faraday"
require_relative "parsers/json_parser"
require_relative "generators/csharp_generator"
require_relative "generators/python_generator"
require_relative "generators/typescript_generator"

class Generator
  def initialize(input, lang, url = nil, insecure = false, nome_classe = "Root", tipo = "interface")
    @input = input
    @lang = lang
    @url = url
    @insecure = insecure
    @nome_classe = nome_classe
    @tipo = tipo
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
      ssl: { verify: !@insecure }
    )

    response = conn.get
    JSON.parse(response.body)
  end
end