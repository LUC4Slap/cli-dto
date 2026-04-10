# frozen_string_literal: true
require 'sinatra/base'
require 'dotenv/load'
require_relative '../db/data_base'
require_relative '../utils/encripty'
require_relative '../utils/token'
require 'byebug'
class AuthServer < Sinatra::Base

  def initialize(app = nil, **_kwargs)
    @db = Database.new
    super
  end

  set :views, File.expand_path('views', __dir__)

  get '/login' do
    erb :'auth/login'
  end

  post '/login' do
    begin
      user = @db.login(params[:email])
      if !user.empty?
        senha_confere = verificar_senha(params[:password], user['password'])
        if senha_confere
          token = gerar_token(user);
          session_data = {
            token: token,
            user: {
              email: params[:email]
            },
            logged_at: Time.now.iso8601
          }

          File.write(
            File.expand_path("~/.dto-cli-session"),
            JSON.pretty_generate(session_data)
          )

          Thread.new do
            sleep 1
            Process.kill("INT", Process.pid)
          end
          return "Usuario logado!"
        end
        File.write(
          File.expand_path("~/.dto-cli-session"),
          JSON.pretty_generate({})
        )
        Thread.new do
          sleep 1
          Process.kill("INT", Process.pid)
        end
        "Usuario ou senha incorreto!"
      else
        File.write(
          File.expand_path("~/.dto-cli-session"),
          JSON.pretty_generate({})
        )
        Thread.new do
          sleep 1
          Process.kill("INT", Process.pid)
        end
        "Usuario ou senha incorreto!"
      end
    rescue
      File.write(
        File.expand_path("~/.dto-cli-session"),
        JSON.pretty_generate({})
      )
      Thread.new do
        sleep 1
        Process.kill("INT", Process.pid)
      end
      """
        <div style='text-align: center; border: 1px solid red; width: 80%; border-radius: 8px;'>
          <h1 style='color: red'>Ops... Ocorreu um erro! tente mais tarde</h1>
        </div>
      """
    end
  end

  get '/create' do
    erb :'auth/create'
  end

  post '/create' do
    begin
      pass_hash = encriptar_senha(params[:password])
      debugger
      @db.cadastrar_usuario(params[:nome], params[:email], pass_hash)
      session_data = {
        token: "fake-token",
        user: {
          email: params[:email]
        },
        logged_at: Time.now.iso8601
      }

      File.write(
        File.expand_path("~/.dto-cli-session"),
        JSON.pretty_generate(session_data)
      )

      Thread.new do
        sleep 1
        Process.kill("INT", Process.pid)
      end
      "Cadastrado com sucesso."
    end
  rescue StandardError => e
    puts "💥 Erro inesperado: #{e.message}"
    exit(1)
  end

end