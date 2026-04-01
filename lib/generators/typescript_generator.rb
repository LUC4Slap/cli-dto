require "active_support/core_ext/string/inflections"

class TypeScriptGenerator
  def initialize(json, nome = "Root")
    @json = json
    @nome = nome
    @classes = {}
  end

  def generate
    if @json.is_a?(Array)
      # Se é um array, processa o primeiro elemento
      if @json.first.is_a?(Hash)
        process_object("Item", @json.first)
        @classes[@nome] = ["    items: Array<Item>;"]
      else
        type = resolve_type("item", @json.first)
        @classes[@nome] = ["    items: Array<#{type}>;"]
      end
    else
      process_object(@nome, @json)
    end

    @classes.map do |name, body|
      <<~TypeScript
      export interface #{name} {
      #{body.join("\n")}
      }
      TypeScript
    end.join("\n")
  end

  private

  def process_object(name, obj)
    return if @classes[name]

    props = obj.map do |key, value|
      type = resolve_type(key, value)
      "    #{camel_case(key)}: #{type};"
    end

    @classes[name] = props
  end

  def resolve_type(key, value)
    case value
    when String then "string"
    when Integer then "number"
    when Float then "number"
    when TrueClass, FalseClass then "boolean"

    when Hash
      class_name = camel_case(key)
      process_object(class_name, value)
      class_name

    when Array
      return "Array<object>" if value.empty?

      first = value.first

      if first.is_a?(Hash)
        class_name = camel_case(key.singularize)
        process_object(class_name, first)
        "Array<#{class_name}>"
      else
        inner = resolve_type(key, first)
        "Array<#{inner}>"
      end

    else
      "object"
    end
  end

  def camel_case(str)
    # Converte para camelCase (primeira letra minúscula)
    parts = str.to_s
               .gsub(/[^a-zA-Z0-9_]/, '_')
               .split('_')
               .reject(&:empty?)
               .map(&:capitalize)
    
    return str if parts.empty?
    parts[0] = parts[0].downcase
    parts.join
  end
end