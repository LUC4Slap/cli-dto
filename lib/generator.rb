require "faraday"
require_relative "parsers/json_parser"

class Generator
  def initialize(input, lang, url = nil)
    @input = input
    @lang = lang
    @url = url
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
    response = Faraday.get(@url)
    JSON.parse(response.body)
  end
end