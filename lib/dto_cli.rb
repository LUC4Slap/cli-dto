require "thor"
require_relative "generator"

class DtoCLI < Thor
  desc "gerar", "Gera DTO a partir de JSON"
  option :input, required: false
  option :url, required: false
  option :lang, required: true

  def gerar
    if options[:input].nil? && options[:url].nil?
      raise "Você deve informar --input ou --url"
    end

    generator = Generator.new(
      options[:input],
      options[:lang],
      options[:url]
    )

    puts generator.generate
  end
end