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
      puts "Esta cor #{@verificar_color} pode ser usado com sucesso!".green
    else
      puts "Esta cor #{@verificar_color} não se encontra, vefifique as cores permitidas".yellow
    end
  end

end
