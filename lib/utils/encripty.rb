# frozen_string_literal: true
require 'bcrypt'

def encriptar_senha(senha)
  password_hash = BCrypt::Password.create(senha)
  password_hash
end

def verificar_senha(senha, password_hash)
  begin
    if BCrypt::Password.new(password_hash) == senha
      true
    else
      false
    end
  rescue
    Thread.new do
      sleep 1
      Process.kill("INT", Process.pid)
    end
  end
end