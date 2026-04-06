require "fileutils"
require "colorize"
require_relative '../error/cli_error'

class DockerGenerator
  def initialize(path: ".", stack: nil, services: [], name: "app", output: "docker-compose.yml")
    @path = path
    @stack = stack
    @services = services.map(&:strip).map(&:downcase)
    @name = name
    @output = output
  end

  def generate_dockerfile
    raise CliError, "Informe --stack para gerar Dockerfile. Suportadas: dotnet, node, nest, fastapi, flask, rails, react, next, vue, nuxt, angular" unless @stack

    content = case @stack
              when "dotnet" then dockerfile_dotnet
              when "node", "nest" then dockerfile_node
              when "fastapi", "flask" then dockerfile_python
              when "rails" then dockerfile_rails
              when "react", "next", "vue", "nuxt", "angular" then dockerfile_frontend
              else raise CliError, "Stack nao suportada para Dockerfile: #{@stack}"
              end

    File.write("#{@path}/Dockerfile", content)

    output = ""
    output << "Dockerfile gerado em #{@path}/Dockerfile\n".green
    output << "Stack: #{@stack}".green
    output
  end

  def generate_compose
    raise CliError, "Informe pelo menos um servico. Ex: --services api,database,redis" if @services.empty?

    content = +""
    content << "version: '3.8'\n\n"
    content << "services:\n"

    @services.each do |svc|
      config = service_yaml(svc)
      if config.nil?
        puts "  Servico desconhecido '#{svc}', ignorando. Disponiveis: api, web, postgres, mysql, mongo, redis, rabbitmq, nginx, worker, adminer, pgadmin, mailhog, minio, elasticsearch".yellow
        next
      end
      content << config
    end

    if @services.include?("postgres") || @services.include?("mysql") || @services.include?("mongo") || @services.include?("redis") || @services.include?("rabbitmq") || @services.include?("minio") || @services.include?("elasticsearch")
      content << "volumes:\n"
      if @services.include?("postgres")
        content << "  postgres_data:\n"
      end
      if @services.include?("mysql")
        content << "  mysql_data:\n"
      end
      if @services.include?("mongo")
        content << "  mongo_data:\n"
      end
      if @services.include?("redis")
        content << "  redis_data:\n"
      end
      if @services.include?("rabbitmq")
        content << "  rabbitmq_data:\n"
      end
      if @services.include?("minio")
        content << "  minio_data:\n"
      end
      if @services.include?("elasticsearch")
        content << "  elasticsearch_data:\n"
      end
    end

    File.write("#{@path}/#{@output}", content)

    output = ""
    output << "docker-compose.yml gerado em #{@path}/#{@output}\n".green
    output << "Servicos: #{@services.join(', ')}".green
    output
  end

  def generate_both
    out = ""
    out << generate_dockerfile << "\n\n" if @stack
    out << generate_compose unless @services.empty?
    out
  end

  private

  # ============================================
  # Dockerfiles
  # ============================================

  def dockerfile_dotnet
    <<~DOCKER
      # Build stage
      FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
      WORKDIR /src
      COPY . .
      RUN dotnet restore
      RUN dotnet publish -c Release -o /app

      # Runtime stage
      FROM mcr.microsoft.com/dotnet/aspnet:8.0
      WORKDIR /app
      COPY --from=build /app .
      EXPOSE 8080
      ENTRYPOINT ["dotnet", "#{@name}.dll"]
    DOCKER
  end

  def dockerfile_node
    <<~DOCKER
      FROM node:20-alpine
      WORKDIR /app
      COPY package*.json ./
      RUN npm ci --only=production
      COPY . .
      EXPOSE 3000
      CMD ["node", "app.js"]
    DOCKER
  end

  def dockerfile_python
    <<~DOCKER
      FROM python:3.12-slim
      WORKDIR /app
      COPY requirements.txt .
      RUN pip install --no-cache-dir -r requirements.txt
      COPY . .
      EXPOSE 8000
      CMD ["python", "main.py"]
    DOCKER
  end

  def dockerfile_rails
    <<~DOCKER
      FROM ruby:3.3-slim
      WORKDIR /app
      RUN apt-get update && apt-get install -y nodejs npm
      COPY Gemfile Gemfile.lock ./
      RUN bundle install
      COPY . .
      EXPOSE 3000
      CMD ["rails", "server", "-b", "0.0.0.0"]
    DOCKER
  end

  def dockerfile_frontend
    <<~DOCKER
      FROM node:20-alpine AS build
      WORKDIR /app
      COPY package*.json ./
      RUN npm ci
      COPY . .
      RUN npm run build

      FROM nginx:alpine
      COPY --from=build /app/build /usr/share/nginx/html
      EXPOSE 80
      CMD ["nginx", "-g", "daemon off;"]
    DOCKER
  end

  # ============================================
  # docker-compose service YAML
  # ============================================

  def service_yaml(name)
    case name
    when "api", "app"      then service_api(name)
    when "web"             then service_web
    when "postgres"        then service_postgres
    when "mysql"           then service_mysql
    when "mongo"           then service_mongo
    when "redis"           then service_redis
    when "rabbitmq"        then service_rabbitmq
    when "nginx"           then service_nginx
    when "worker"          then service_worker
    when "adminer"         then service_adminer
    when "pgadmin"         then service_pgadmin
    when "mailhog"         then service_mailhog
    when "minio"           then service_minio
    when "elasticsearch"   then service_elasticsearch
    else
      nil
    end
  end

  def service_api(name)
    <<~YAML
      #{name}:
        build:
          context: .
          dockerfile: Dockerfile
        ports:
          - "3000:3000"
        environment:
          - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/#{@name}
        depends_on:
          - postgres
        restart: unless-stopped
    YAML
  end

  def service_web
    <<~YAML
      web:
        build:
          context: .
          dockerfile: Dockerfile
        ports:
          - "3000:3000"
        depends_on:
          - api
        restart: unless-stopped
    YAML
  end

  def service_postgres
    <<~YAML
      postgres:
        image: postgres:16-alpine
        ports:
          - "5432:5432"
        environment:
          - POSTGRES_USER=postgres
          - POSTGRES_PASSWORD=postgres
          - POSTGRES_DB=#{@name}
        volumes:
          - postgres_data:/var/lib/postgresql/data
        restart: unless-stopped
    YAML
  end

  def service_mysql
    <<~YAML
      mysql:
        image: mysql:8
        ports:
          - "3306:3306"
        environment:
          - MYSQL_ROOT_PASSWORD=root
          - MYSQL_DATABASE=#{@name}
        volumes:
          - mysql_data:/var/lib/mysql
        restart: unless-stopped
    YAML
  end

  def service_mongo
    <<~YAML
      mongo:
        image: mongo:7
        ports:
          - "27017:27017"
        environment:
          - MONGO_INITDB_ROOT_USERNAME=mongo
          - MONGO_INITDB_ROOT_PASSWORD=mongo
        volumes:
          - mongo_data:/data/db
        restart: unless-stopped
    YAML
  end

  def service_redis
    <<~YAML
      redis:
        image: redis:7-alpine
        ports:
          - "6379:6379"
        volumes:
          - redis_data:/data
        restart: unless-stopped
    YAML
  end

  def service_rabbitmq
    <<~YAML
      rabbitmq:
        image: rabbitmq:3-management
        ports:
          - "5672:5672"
          - "15672:15672"
        environment:
          - RABBITMQ_DEFAULT_USER=guest
          - RABBITMQ_DEFAULT_PASS=guest
        volumes:
          - rabbitmq_data:/var/lib/rabbitmq
        restart: unless-stopped
    YAML
  end

  def service_nginx
    <<~YAML
      nginx:
        image: nginx:alpine
        ports:
          - "80:80"
        volumes:
          - ./nginx.conf:/etc/nginx/nginx.conf:ro
        depends_on:
          - api
        restart: unless-stopped
    YAML
  end

  def service_worker
    <<~YAML
      worker:
        build:
          context: .
          dockerfile: Dockerfile
        command: bundle exec sidekiq
        environment:
          - REDIS_URL=redis://redis:6379
        depends_on:
          - api
          - redis
        restart: unless-stopped
    YAML
  end

  def service_adminer
    <<~YAML
      adminer:
        image: adminer
        ports:
          - "8080:8080"
        depends_on:
          - postgres
        restart: unless-stopped
    YAML
  end

  def service_pgadmin
    <<~YAML
      pgadmin:
        image: dpage/pgadmin4
        ports:
          - "5050:80"
        environment:
          - PGADMIN_DEFAULT_EMAIL=admin@admin.com
          - PGADMIN_DEFAULT_PASSWORD=admin
        depends_on:
          - postgres
        restart: unless-stopped
    YAML
  end

  def service_mailhog
    <<~YAML
      mailhog:
        image: mailhog/mailhog
        ports:
          - "1025:1025"
          - "8025:8025"
        restart: unless-stopped
    YAML
  end

  def service_minio
    <<~YAML
      minio:
        image: minio/minio
        ports:
          - "9000:9000"
          - "9001:9001"
        volumes:
          - minio_data:/data
        environment:
          - MINIO_ROOT_USER=minioadmin
          - MINIO_ROOT_PASSWORD=minioadmin
        command: server /data --console-address :9001
        restart: unless-stopped
    YAML
  end

  def service_elasticsearch
    <<~YAML
      elasticsearch:
        image: elasticsearch:8.12.0
        ports:
          - "9200:9200"
        environment:
          - discovery.type=single-node
          - xpack.security.enabled=false
        volumes:
          - elasticsearch_data:/usr/share/elasticsearch/data
        restart: unless-stopped
    YAML
  end
end
