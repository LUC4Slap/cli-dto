# frozen_string_literal: true

require "json"

class JsonParser
  def self.parse(file_path)
    JSON.parse(File.read(file_path))
  end
end