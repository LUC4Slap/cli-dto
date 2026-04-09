# frozen_string_literal: true
require 'wikipedia'
require_relative "../config/wikipedia"
class Search
  def initialize(busca = nil)
    @busca = busca
  end
  def buscar
    page = Wikipedia.find(@busca)
    if page.content.include?("#REDIRECIONAMENTO")
      redirect = page.content.match(/\[\[(.*?)\]\]/)[1]
      page = Wikipedia.find(redirect)
    end

    page.summary || "Nenhum resumo encontrado."
  end
end
