# frozen_string_literal: true
require "sqlite3"
require 'json'
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

  def salvar_dto(nome, lang, tipo, json_payload, codigo)
    @db.execute(
      "INSERT INTO dtos_salvos (nome, lang, tipo, json_payload, codigo, criado_em) VALUES (?, ?, ?, ?, ?, ?)",
      [nome, lang, tipo, json_payload, codigo, Time.now.to_s]
    )
  end

  def listar_dtos(busca = nil)
    query = "SELECT * FROM dtos_salvos ORDER BY criado_em DESC"
    if busca
      query += " WHERE nome LIKE '%#{busca}%'"
    end
    @db.execute(query).map do |row|
      {
        id: row[0],
        nome: row[1],
        lang: row[2],
        tipo: row[3],
        json_payload: row[4],
        codigo: row[5],
        criado_em: row[6]
      }
    end
  end

  def buscar_dto(id)
    row = @db.execute("SELECT * FROM dtos_salvos WHERE id = ?", [id]).first
    return nil unless row
    {
      id: row[0],
      nome: row[1],
      lang: row[2],
      tipo: row[3],
      json_payload: row[4],
      codigo: row[5],
      criado_em: row[6]
    }
  end

  def deletar_dto(id)
    @db.execute("DELETE FROM dtos_salvos WHERE id = ?", [id])
  end

  def salvar_crud(lang, codigo, entidades)
    @db.execute(
      "INSERT INTO crud_salvos (lang, codigo, entidades, criado_em) VALUES (?, ?, ?, ?)",
      [lang, codigo.to_s, entidades.to_json, Time.now.to_s]
    )
  end

  def listar_cruds
    @db.execute("SELECT * FROM crud_salvos ORDER BY criado_em DESC").map do |row|
      { id: row[0], lang: row[1], codigo: row[2], entidades: row[3], criado_em: row[4] }
    end
  end

  # ============================================
  # Analytics -- baseado na tabela comandos
  # ============================================

  def estatisticas
    comandos = @db.execute("SELECT nome, comando, criado_em FROM comandos ORDER BY criado_em DESC")
    total = comandos.size
    return { total: 0, cmd_chart: [], lang_chart: [], options_chart: [], params_chart: [], recentes: [] } if total == 0

    # Comandos mais usados
    cmd_rows = @db.execute("SELECT nome, COUNT(*) as cnt FROM comandos GROUP BY nome ORDER BY cnt DESC")
    cmd_chart = cmd_rows.map { |r| { nome: r[0], total: r[1], pct: ((r[1].to_f / total) * 100).round(1) } }

    # Linguagens mais usadas (extrai do campo comando)
    lang_count = Hash.new(0)
    options_count = Hash.new(0)
    params_count = Hash.new(0)

    comandos.each do |cmd_nome, cmd_str, criado_em|
      next unless %w[gerar gerar_crud].include?(cmd_nome)
      params = parse_comando(cmd_str)
      next unless params

      lang = params["lang"]
      lang_count[lang] += 1 if lang

      # Parametros usados (sem contar flags com valor default ou vazio)
      params.each do |key, value|
        next if %w[insecure color path].include?(key)
        next if value.to_s.empty? || value == "false" || value == "true"
        params_count[key.to_s] += 1
      end

      # Opcoes booleanas habilitadas
      if params["insecure"] == "true"
        options_count["--insecure"] += 1
      end
      if params["tipo"] && params["tipo"] != "interface"
        options_count["--tipo=#{params["tipo"]}"] += 1
      end
      if params["db"] && !params["db"].to_s.empty?
        options_count["--db"] += 1
      end
    end

    lang_chart = lang_count.sort_by { |_, v| -v }.map { |k, v| { nome: k, total: v, pct: ((v.to_f / total) * 100).round(1) } }

    params_chart = params_count.sort_by { |_, v| -v }.first(10).map { |k, v| { nome: "--#{k}", total: v, pct: ((v.to_f / total) * 100).round(1) } }

    # Comandos recentes
    recentes = comandos.first(8).map { |cmd_nome, cmd_str, criado_em| { nome: cmd_nome, criado_em: criado_em } }

    {
      total: total,
      cmd_chart: cmd_chart,
      lang_chart: lang_chart,
      options_chart: [],
      params_chart: params_chart,
      recentes: recentes
    }
  end

  def total_comandos
    row = @db.execute("SELECT COUNT(*) FROM comandos").first
    row ? row[0] : 0
  end

  private

  def parse_comando(hash_str)
    return nil if hash_str.to_s.empty? || hash_str == "{}"
    begin
      # O formato e Ruby hash: {"key"=>"value"}
      # Converte para JSON: {"key":"value"}
      json_str = hash_str.gsub("=>", ":")
      JSON.parse(json_str)
    rescue
      begin
        # Tenta eval seguro (apenas para hash simples)
        nil
      rescue
        nil
      end
    end
  end

  def criar_banco
    db_path = "comandos.db"

    exists = File.exist?(db_path)

    db = SQLite3::Database.new(db_path)

    if !exists
      @cor_texto.printar_colorido("🆕 Banco criado")
      criar_tabelas(db)
    else
      migrar_se_necessario(db)
    end
    db
  end

  def migrar_se_necessario(db)
    tables = db.execute("SELECT name FROM sqlite_master WHERE type='table'").flatten

    unless tables.include?("dtos_salvos")
      db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS dtos_salvos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        lang TEXT,
        tipo TEXT,
        json_payload TEXT,
        codigo TEXT,
        criado_em DATETIME
      );
      SQL
    end

    unless tables.include?("crud_salvos")
      db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS crud_salvos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lang TEXT,
        codigo TEXT,
        entidades TEXT,
        criado_em DATETIME
      );
      SQL
    end
  end

  def criar_tabelas(db)
    db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS comandos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT,
      comando TEXT,
      criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS dtos_salvos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT,
      lang TEXT,
      tipo TEXT,
      json_payload TEXT,
      codigo TEXT,
      criado_em DATETIME
    );

    CREATE TABLE IF NOT EXISTS crud_salvos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      lang TEXT,
      codigo TEXT,
      entidades TEXT,
      criado_em DATETIME
    );
    SQL
  end
end
