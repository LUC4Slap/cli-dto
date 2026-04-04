# frozen_string_literal: true
require "sqlite3"
require_relative '../cores/cores'
require "byebug"

class Database
  def initialize()
    @cor_texto = Cores.new("yellow")
    @db = criar_banco
  end

  def salvar_comando(nome, comando)
    @db.execute(
      "INSERT INTO comandos (nome, comando) VALUES (?, ?)",
      [nome, comando]
    )
  end

  def listar_comandos(busca = nil?)
    query = "SELECT * FROM comandos"
    if !busca.nil?
      query += " where #{busca}"
    end
    @db.execute(query)
  end

  private

  def criar_banco
    db_path = "comandos.db"

    exists = File.exist?(db_path)

    db = SQLite3::Database.new(db_path)

    if !exists
      @cor_texto.printar_colorido("🆕 Banco criado")
      criar_tabelas(db)
    end
    db
  end

  def criar_tabelas(db)
    db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS comandos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT,
      comando TEXT,
      criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    SQL
  end
end
