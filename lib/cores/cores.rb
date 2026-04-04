# frozen_string_literal: true
require 'colorized_string'
class Cores
  def initialize(cor = "")
    @verificar_color = cor
    @cores_lib = ColorizedString.colors
  end

  def cores_existentes()
    puts @cores_lib.join(", ").green
  end

  def verificar_se_cor_existe()
    cor_simbolo = @verificar_color.to_sym
    cor_existe = @cores_lib.include?(cor_simbolo)
    if cor_existe
      printar_colorido("Esta cor '#{@verificar_color}' pode ser usado com sucesso!", "green")
    else
      printar_colorido("Esta cor '#{@verificar_color}' não se encontra, vefifique as cores permitidas", "yellow")
    end
  end

  def printar_colorido(texto = "", cor = nil)
    raise CliError, "Informe uma mensagem" if texto.empty?
    if !cor.nil?
      cor = verificar_color(cor) ? cor : "green"
      puts texto.send(cor)
    else
      puts texto.send(@verificar_color)
    end
  end

  private
  def verificar_color(cor = nil)
    cor_simbolo = cor ? cor.to_sym : @verificar_color.to_sym
    cor_existe = @cores_lib.include?(cor_simbolo)
    cor_existe
  end

end
