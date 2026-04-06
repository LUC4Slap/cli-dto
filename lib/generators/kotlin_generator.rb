require "active_support/core_ext/string/inflections"
require "colorize"

class KotlinGenerator
  def initialize(json, nome_classe = "Root")
    @json = json
    @nome_classe = nome_classe
    @classes = {}
  end

  def generate
    if @json.is_a?(Array)
      process_object("Root", @json.first)
    else
      @json.each do |key, value|
        if value.is_a?(Hash) && !primitive?(value)
          process_object(key.to_s.classify, value)
        end
      end
    end

    output = ""
    output << "\n".green
    output << "Gerando data classes Kotlin...\n".green
    output << "-" * 40 + "\n".green
    output << "\n".green

    @classes.each do |class_name, fields|
      kotlin_code = generate_class(class_name, fields)
      output << kotlin_code
      output << "\n".green
    end

    output << "\n".green
    output << "Total: #{@classes.count} classe(s) gerada(s) com sucesso!".green
    output
  end

  private

  def generate_class(name, fields)
    lines = ["data class #{name}("]
    fields.each_with_index do |(field_name, type_info), index|
      comma = index < fields.size - 1 ? "," : ""
      default = type_info[:nullable] ? " = null" : ""
      nullable_marker = type_info[:nullable] ? "?" : ""
      lines << "    val #{field_name}: #{type_info[:type]}#{nullable_marker}#{default}#{comma}"
    end
    lines << ")"
    lines.join("\n")
  end

  def process_object(name, obj)
    fields = {}
    obj.each do |key, value|
      type_info = resolve_type(key, value, obj)
      fields[key.to_s.camelize(:lower)] = type_info
    end
    @classes[name] = fields

    obj.each do |key, value|
      if value.is_a?(Hash) && !primitive?(value)
        process_object(key.to_s.classify, value)
      end
    end
  end

  def resolve_type(key, value, parent = nil)
    case value
    when Hash
      { type: key.to_s.classify, nullable: true }
    when Array
      if value.empty?
        { type: "List<Any>", nullable: true }
      elsif value.first.is_a?(Hash)
        { type: "List<#{key.to_s.classify.singularize || key.to_s.classify}>", nullable: true }
      else
        { type: "List<#{kotlin_type(value.first)}>", nullable: true }
      end
    when Integer then { type: "Int", nullable: false }
    when Float then { type: "Double", nullable: false }
    when String then { type: "String", nullable: true }
    when true, false then { type: "Boolean", nullable: false }
    when nil then { type: "Any", nullable: true }
    else { type: "Any", nullable: true }
    end
  end

  def kotlin_type(value)
    case value
    when Integer then "Int"
    when Float then "Double"
    when String then "String"
    when true, false then "Boolean"
    else "Any"
    end
  end

  def primitive?(obj)
    !obj.is_a?(Hash) && !obj.is_a?(Array)
  end
end
