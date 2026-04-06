require "active_support/core_ext/string/inflections"
require "colorize"

class SwiftGenerator
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
    output << "Gerando structs Swift...\n".green
    output << "-" * 40 + "\n".green
    output << "\n".green

    @classes.each do |class_name, fields|
      swift_code = generate_struct(class_name, fields)
      output << swift_code
      output << "\n".green
    end

    output << "\n".green
    output << "Total: #{@classes.count} struct(s) gerada(s) com sucesso!".green
    output
  end

  private

  def generate_struct(name, fields)
    lines = ["struct #{name}: Codable {"]
    fields.each do |field_name, type_info|
      snake_name = field_name.underscore
      if snake_name != field_name
        lines << "    enum CodingKeys: String, CodingKey { case #{field_name} = \"#{snake_name}\" }"
      end
      wrapper = type_info[:optional] ? "var" : "let"
      lines << "    #{wrapper} #{field_name}: #{type_info[:type]}"
    end
    lines << "}"
    lines.join("\n")
  end

  def process_object(name, obj)
    fields = {}
    obj.each do |key, value|
      type_info = resolve_type(key, value, obj)
      fields[key.to_s.classify] = type_info
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
      { type: key.to_s.classify, optional: true }
    when Array
      if value.empty?
        { type: "[Any]", optional: true }
      elsif value.first.is_a?(Hash)
        { type: "[#{key.to_s.classify.singularize || key.to_s.classify}]", optional: true }
      else
        { type: "[#{swift_type(value.first)}]", optional: true }
      end
    when Integer then { type: "Int", optional: false }
    when Float then { type: "Double", optional: false }
    when String then { type: "String", optional: true }
    when true, false then { type: "Bool", optional: false }
    when nil then { type: "Any", optional: true }
    else { type: "Any", optional: true }
    end
  end

  def swift_type(value)
    case value
    when Integer then "Int"
    when Float then "Double"
    when String then "String"
    when true, false then "Bool"
    else "Any"
    end
  end

  def primitive?(obj)
    !obj.is_a?(Hash) && !obj.is_a?(Array)
  end
end
