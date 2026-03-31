# frozen_string_literal: true

require_relative "parsers/json_parser"
require_relative "generators/csharp_generator"
require_relative "generators/python_generator"

class Generator
  def initialize(input, lang)
    @input = input
    @lang = lang
  end

  def generate
    json = JsonParser.parse(@input)

    case @lang
    when "csharp"
      CSharpGenerator.new(json).generate
    when "python"
      PythonGenerator.new(json).generate
    else
      raise "Linguagem não suportada"
    end
  end
end