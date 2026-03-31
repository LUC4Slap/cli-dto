# frozen_string_literal: true

require "thor"
require_relative "generator"

class DtoCLI < Thor
  desc "gerar", "Gera DTO a partir de JSON"
  option :input, required: true
  option :lang, required: true

  def gerar
    generator = Generator.new(options[:input], options[:lang])
    puts generator.generate
  end
end