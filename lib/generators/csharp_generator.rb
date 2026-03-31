# frozen_string_literal: true
require "active_support/core_ext/string/inflections"

class CSharpGenerator
  def initialize(json)
    @json = json
    @classes = {}
  end

  def generate
    process_object("Root", @json)

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
    str.to_s.split('_').map(&:capitalize).join
  end
end