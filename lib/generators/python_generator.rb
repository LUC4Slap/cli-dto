# frozen_string_literal: true

class PythonGenerator
  def initialize(json)
    @json = json
  end

  def generate
    props = @json.map do |key, value|
      "#{key}: #{map_type(value)}"
    end

    <<~PY
    from pydantic import BaseModel

    class Model(BaseModel):
        #{props.join("\n    ")}
    PY
  end

  private

  def map_type(value)
    case value
    when String then "str"
    when Integer then "int"
    when Float then "float"
    when TrueClass, FalseClass then "bool"
    when Array then "list"
    when Hash then "dict"
    else "Any"
    end
  end
end