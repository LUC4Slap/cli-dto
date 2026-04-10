# frozen_string_literal: true
require 'jwt'
require 'byebug'

def gerar_token(payload = nil)
  secret = ENV['PASS_JWT']
  if payload.nil?
    raise CliError, 'Erro para gerar o token'
  end

   JWT.encode(payload, secret, 'HS256')
end