# frozen_string_literal: true

class CSharpGenerator
  def initialize(json)
    @json = json
  end

  def generate
    generate_class("Root", @json)
  end

  private

  def generate_class(name, obj)
    props = obj.map do |key, value|
      type = map_type(value)
      "    public #{type} #{camel_case(key)} { get; set; }"
    end

    <<~CSharp
    public class #{name}
    {
    #{props.join("\n")}
    }
    CSharp
  end

  def map_type(value)
    case value
    when String then "string"
    when Integer then "int"
    when Float then "double"
    when TrueClass, FalseClass then "bool"
    when Array
      inner = map_type(value.first)
      "List<#{inner}>"
    when Hash
      "object"
    else
      "object"
    end
  end

  def camel_case(str)
    str.split('_').map(&:capitalize).join
  end
end