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
          token = gerar_token(user)
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
          
          @icon = 'bi bi-check-lg'
          @title = 'Login realizado com sucesso!'
          @message = 'Você será redirecionado em instantes...'
          return erb :'auth/success'
        end
        
        File.write(
          File.expand_path("~/.dto-cli-session"),
          JSON.pretty_generate({})
        )
        Thread.new do
          sleep 1
          Process.kill("INT", Process.pid)
        end
        
        @type = 'danger'
        @icon = 'bi bi-x-lg'
        @title = 'Credenciais inválidas'
        @message = 'Email ou senha incorretos. Verifique seus dados e tente novamente.'
        erb :'auth/error'
      else
        File.write(
          File.expand_path("~/.dto-cli-session"),
          JSON.pretty_generate({})
        )
        Thread.new do
          sleep 1
          Process.kill("INT", Process.pid)
        end
        
        @type = 'danger'
        @icon = 'bi bi-x-lg'
        @title = 'Credenciais inválidas'
        @message = 'Email ou senha incorretos. Verifique seus dados e tente novamente.'
        erb :'auth/error'
      end
    rescue => e
      File.write(
        File.expand_path("~/.dto-cli-session"),
        JSON.pretty_generate({})
      )
      Thread.new do
        sleep 1
        Process.kill("INT", Process.pid)
      end

      @type = 'warning'
      @icon = 'bi bi-exclamation-triangle'
      @title = 'Ops! Algo deu errado'
      @message = 'Ocorreu um erro inesperado. Por favor, tente novamente mais tarde.'
      erb :'auth/error'
    end
  end

  get '/create' do
    erb :'auth/create'
  end

  post '/create' do
    begin
      pass_hash = encriptar_senha(params[:password])
      @db.cadastrar_usuario(params[:nome], params[:email], pass_hash)
      
      session_data = {
        token: gerar_token({nome: params[:nome], email: params[:email]}),
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
      
      @icon = 'bi bi-person-check'
      @title = 'Cadastro realizado com sucesso!'
      @message = 'Bem-vindo ao DTO CLI. Você será redirecionado em instantes...'
      erb :'auth/success'
    rescue StandardError => e
      File.write(
        File.expand_path("~/.dto-cli-session"),
        JSON.pretty_generate({})
      )
      
      Thread.new do
        sleep 1
        Process.kill("INT", Process.pid)
      end
      
      @type = 'warning'
      @icon = 'bi bi-exclamation-triangle'
      @title = 'Erro ao criar conta'
      @message = 'Não foi possível criar sua conta. Verifique se o email já está cadastrado ou tente novamente mais tarde.'
      erb :'auth/error'
    end
  end

end