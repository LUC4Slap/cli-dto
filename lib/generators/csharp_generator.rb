# frozen_string_literal: true
require "active_support/core_ext/string/inflections"
require 'json'

class CSharpGenerator
  def initialize(json)
    @json = json
    @classes = {}
  end

  def generate
    if @json.is_a?(Array)
      # Se é um array, processa o primeiro elemento
      if @json.first.is_a?(Hash)
        process_object("Item", @json.first)
        @classes["Root"] = ["    public List<Item> Items { get; set; }"]
      else
        type = resolve_type("item", @json.first)
        @classes["Root"] = ["    public List<#{type}> Items { get; set; }"]
      end
    else
      process_object("Root", @json)
    end

    @classes.map do |name, body|
      <<~CSharp
        public class #{name}
        {
        #{body.join("\n")}
        }
      CSharp
    end.join("\n")
  end

  private

  def process_object(name, obj)
    return if @classes[name]

    props = obj.map do |key, value|
      type = resolve_type(key, value)
      "    public #{type} #{camel_case(key)} { get; set; }"
    end

    @classes[name] = props
  end

  def resolve_type(key, value)
    case value
    when String then "string"
    when Integer then "int"
    when Float then "double"
    when TrueClass, FalseClass then "bool"

    when Hash
      class_name = camel_case(key)
      process_object(class_name, value)
      class_name

    when Array
      return "List<object>" if value.empty?

      first = value.first

      if first.is_a?(Hash)
        class_name = camel_case(key.singularize)
        process_object(class_name, first)
        "List<#{class_name}>"
      else
        inner = resolve_type(key, first)
        "List<#{inner}>"
      end

    else
      "object"
    end
  end

  def camel_case(str)
    # Converte para PascalCase (primeira letra maiúscula)
    str.to_s
       .gsub(/[^a-zA-Z0-9_]/, '_')  # substitui caracteres especiais por _
       .split('_')
       .reject(&:empty?)
       .map(&:capitalize)
       .join
  end
end