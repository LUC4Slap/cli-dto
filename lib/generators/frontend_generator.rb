# frozen_string_literal: true

class FrontendGenerator
  def initialize(stack, nome, path)
    @stack = stack
    @nome = nome
    @path = path
  end

  def generate
    full_path = File.join(@path, @nome)

    case @stack
    when "angular"
      run("npx @angular/cli new #{@nome} --directory #{full_path}")

    when "react"
      run("npx create-react-app #{@nome}")
      move_project(full_path)

    when "next"
      run("npx create-next-app@latest #{@nome}")
      move_project(full_path)

    when "vue"
      run("npm create vue@latest #{@nome}")
      move_project(full_path)

    when "nuxt"
      run("npx nuxi init #{@nome}")
      move_project(full_path)

    else
      puts "Stack não suportada"
    end
  end

  private

  def run(cmd)
    puts "🚀 #{cmd}"
    system(cmd)
  end

  def move_project(target_path)
    if Dir.exist?(@nome)
      FileUtils.mv(@nome, target_path)
    end
  end
end