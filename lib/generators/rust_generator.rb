require "active_support/core_ext/string/inflections"
require "colorize"

class RustGenerator
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
    output << "Gerando structs Rust...\n".green
    output << "-" * 40 + "\n".green
    output << "\n".green

    @classes.each do |class_name, fields|
      rust_code = generate_struct(class_name, fields)
      output << rust_code
      output << "\n".green
    end

    output << "\n".green
    output << "Total: #{@classes.count} struct(s) gerada(s) com sucesso!".green
    output
  end

  private

  def generate_struct(name, fields)
    lines = ["#[derive(Debug, Serialize, Deserialize)]", "pub struct #{name} {"]
    fields.each_with_index do |(field_name, type_info), index|
      snake_name = field_name.underscore
      comma = index < fields.size - 1 ? "," : ""
      if snake_name != field_name.underscore
        lines << "    #[serde(rename = \"#{snake_name}\")]"
      end
      opt = type_info[:optional] ? "Option<" : ""
      opt_close = type_info[:optional] ? ">" : ""
      lines << "    pub #{field_name.underscore}: #{opt}#{type_info[:type]}#{opt_close}#{comma}"
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
        { type: "Vec<serde_json::Value>", optional: true }
      elsif value.first.is_a?(Hash)
        { type: "Vec<#{key.to_s.classify.singularize || key.to_s.classify}>", optional: true }
      else
        { type: "Vec<#{rust_type(value.first)}>", optional: true }
      end
    when Integer then { type: "i64", optional: false }
    when Float then { type: "f64", optional: false }
    when String then { type: "String", optional: true }
    when true, false then { type: "bool", optional: false }
    when nil then { type: "serde_json::Value", optional: true }
    else { type: "serde_json::Value", optional: true }
    end
  end

  def rust_type(value)
    case value
    when Integer then "i64"
    when Float then "f64"
    when String then "String"
    when true, false then "bool"
    else "serde_json::Value"
    end
  end

  def primitive?(obj)
    !obj.is_a?(Hash) && !obj.is_a?(Array)
  end
end
