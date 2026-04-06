require "active_support/core_ext/string/inflections"
require "colorize"

class JavaGenerator
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
    output << "Gerando classes Java...\n".green
    output << "-" * 40 + "\n".green
    output << "\n".green

    @classes.each do |class_name, fields|
      java_code = generate_class(class_name, fields[:fields])
      output << java_code
      output << "\n".green
    end

    output << "\n".green
    output << "Total: #{@classes.count} classe(s) gerada(s) com sucesso!".green
    output
  end

  private

  def generate_class(name, fields)
    lines = ["public class #{name} {", ""]

    fields.each do |field_name, type_info|
      lines << "    private #{type_info[:type]} #{field_name};"
    end

    lines << ""

    fields.each do |field_name, type_info|
      capitalized = field_name.classify
      type_str = type_info[:type]

      lines << "    public #{type_str} get#{capitalized}() {"
      lines << "        return #{field_name};"
      lines << "    }"
      lines << ""
      lines << "    public void set#{capitalized}(#{type_str} #{field_name}) {"
      lines << "        this.#{field_name} = #{field_name};"
      lines << "    }"
      lines << ""
    end

    lines << "}"
    lines.join("\n")
  end

  def process_object(name, obj)
    fields = {}
    obj.each do |key, value|
      type_info = resolve_type(key, value, obj)
      fields[key.to_s.camelize(:lower)] = type_info
    end
    @classes[name] = { fields: fields }

    obj.each do |key, value|
      if value.is_a?(Hash) && !primitive?(value)
        process_object(key.to_s.classify, value)
      end
    end
  end

  def resolve_type(key, value, parent = nil)
    case value
    when Hash
      { type: key.to_s.classify }
    when Array
      if value.empty?
        { type: "List<Object>" }
      elsif value.first.is_a?(Hash)
        { type: "List<#{key.to_s.classify.singularize || key.to_s.classify}>" }
      else
        { type: "List<#{java_type(value.first)}>" }
      end
    when Integer then { type: "Integer" }
    when Float then { type: "Double" }
    when String then { type: "String" }
    when true, false then { type: "Boolean" }
    when nil then { type: "Object" }
    else { type: "Object" }
    end
  end

  def java_type(value)
    case value
    when Integer then "Integer"
    when Float then "Double"
    when String then "String"
    when true, false then "Boolean"
    else "Object"
    end
  end

  def primitive?(obj)
    !obj.is_a?(Hash) && !obj.is_a?(Array)
  end
end
