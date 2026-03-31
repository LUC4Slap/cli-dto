# frozen_string_literal: true

class EnvGenerator
  def self.create_basic(path)
    File.write("#{path}/.env", <<~ENV)
      # Ambiente
      APP_ENV=development

      # Porta padrão
      PORT=3000

      # Database
      DATABASE_URL=

      # JWT
      JWT_SECRET=changeme
    ENV

    puts "📄 .env criado"
  end
end