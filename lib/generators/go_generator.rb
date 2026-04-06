require "active_support/core_ext/string/inflections"
require "colorize"

class GoGenerator
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
    output << "📦 Gerando structs Go...\n".green
    output << "—" * 40 + "\n".green
    output << "\n".green

    @classes.each do |class_name, fields|
      go_code = generate_struct(class_name, fields)
      output << go_code
      output << "\n".green
    end

    output << "\n".green
    output << "Total: #{@classes.count} struct(s) gerada(s) com sucesso!".green
    output
  end

  private

  def generate_struct(name, fields)
    lines = ["type #{name} struct {"]
    fields.each do |key, type|
      tag = key.to_s.gsub(/([A-Z])/) { " #{$1}" }.strip.split.join("_")
      tag = tag.underscore
      lines << "    #{key.to_s.classify} #{type} `json:\"#{tag}\"`"
    end
    lines << "}"
    lines.join("\n") + "\n"
  end

  def process_object(name, obj)
    fields = {}
    obj.each do |key, value|
      type = resolve_type(key, value, obj)
      fields[key] = type
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
      "#{key.to_s.classify}"
    when Array
      if value.empty?
        "[]interface{}"
      elsif value.first.is_a?(Hash)
        "[]#{resolve_array_item_type(value.first, key)}"
      else
        case value.first
        when Integer then "[]int"
        when Float then "[]float64"
        when String then "[]string"
        when true, false then "[]bool"
        else "[]interface{}"
        end
      end
    when Integer then "int"
    when Float then "float64"
    when String then "string"
    when true, false then "bool"
    when nil then "interface{}"
    else "interface{}"
    end
  end

  def resolve_array_item_type(item, key)
    case item
    when Hash
      return "#{key.to_s.classify.singularize || key.to_s.classify}"
    when Integer then "int"
    when Float then "float64"
    when String then "string"
    when true, false then "bool"
    else "interface{}"
    end
  end

  def primitive?(obj)
    !obj.is_a?(Hash) && !obj.is_a?(Array)
  end
end
