# frozen_string_literal: true
require "active_support/core_ext/string/inflections"

class PythonGenerator
  def initialize(json)
    @json = json
    @classes = {}
  end

  def generate
    if @json.is_a?(Array)
      # Se é um array, processa o primeiro elemento
      if @json.first.is_a?(Hash)
        process_object("Item", @json.first)
        @classes["Root"] = ["    items: list[Item]"]
      else
        type = resolve_type("item", @json.first)
        @classes["Root"] = ["    items: list[#{type}]"]
      end
    else
      process_object("Root", @json)
    end

    result = "from pydantic import BaseModel\nfrom typing import List, Optional\n\n"
    
    @classes.map do |name, body|
      result += <<~PY
      class #{name}(BaseModel):
      #{body.join("\n")}

      PY
    end
    
    result
  end

  private

  def process_object(name, obj)
    return if @classes[name]

    props = obj.map do |key, value|
      type = resolve_type(key, value)
      "    #{snake_case(key)}: #{type}"
    end

    @classes[name] = props
  end

  def resolve_type(key, value)
    case value
    when String then "str"
    when Integer then "int"
    when Float then "float"
    when TrueClass, FalseClass then "bool"

    when Hash
      class_name = pascal_case(key)
      process_object(class_name, value)
      class_name

    when Array
      return "list" if value.empty?

      first = value.first

      if first.is_a?(Hash)
        class_name = pascal_case(key.singularize)
        process_object(class_name, first)
        "list[#{class_name}]"
      else
        inner = resolve_type(key, first)
        "list[#{inner}]"
      end

    else
      "object"
    end
  end

  def snake_case(str)
    str.to_s
       .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
       .gsub(/([a-z\d])([A-Z])/, '\1_\2')
       .downcase
  end

  def pascal_case(str)
    str.to_s
       .gsub(/[^a-zA-Z0-9_]/, '_')
       .split('_')
       .reject(&:empty?)
       .map(&:capitalize)
       .join
  end
end