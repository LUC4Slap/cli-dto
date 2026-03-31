require "faraday"
require_relative "parsers/json_parser"
require_relative "generators/csharp_generator"
require_relative "generators/python_generator"

class Generator
  def initialize(input, lang, url = nil, insecure = false)
    @input = input
    @lang = lang
    @url = url
    @insecure = insecure
  end

  def generate
    json = @url ? fetch_from_url : JsonParser.parse(@input)

    case @lang
    when "csharp"
      CSharpGenerator.new(json).generate
    when "python"
      PythonGenerator.new(json).generate
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