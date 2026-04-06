require "active_support/core_ext/string/inflections"
require "colorize"
require "fileutils"
require "yaml"
require "faraday"
require "json"
require_relative '../error/cli_error'
require_relative '../parsers/json_parser'

class ControllerGenerator
  def initialize(json, lang: "dotnet", path: ".", framework: "default")
    @json = json
    @lang = lang.to_s
    @path = path
    @framework = framework.to_s
    @classes = {}
  end

  def generate
    case @lang
    when "dotnet", "csharp", "cs"
      generate_dotnet
    when "node", "js", "javascript"
      generate_node
    when "python", "py"
      generate_python
    when "ts", "typescript"
      generate_typescript
    else
      raise CliError, "Linguagem não suportada para geração de controller. Suportadas: dotnet, node, python, typescript"
    end
  end

  private

  def generate_dotnet
    controller_names = []
    services = []
    repositories = []

    root_name = @json.is_a?(Array) ? "Root" : (@json.keys.first || "Root")
    root_name = root_name.to_s.classify

    if @json.is_a?(Array)
      process_object("Item", @json.first)
    else
      @json.each do |key, value|
        name = key.to_s.classify
        if value.is_a?(Hash) && !primitive?(value)
          process_object(name, value)
        end
      end
    end

    @classes.each do |class_name, fields|
      controller_name = "#{class_name}Controller"
      service_name = "#{class_name}Service"
      repository_name = "#{class_name}Repository"
      entity_name = class_name

      controller_names << controller_name
      services << service_name
      repositories << repository_name

      controller_dir = "#{@path}/Controllers"
      service_dir = "#{@path}/Services"
      repository_dir = "#{@path}/Repositories"

      [controller_dir, service_dir, repository_dir].each do |dir|
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      end

      namespace = File.basename(File.expand_path(@path))

      # Generate Controller
      controller_code = generate_dotnet_controller(namespace, controller_name, service_name, entity_name, fields)
      File.write("#{controller_dir}/#{controller_name}.cs", controller_code)

      # Generate Service
      service_code = generate_dotnet_service(namespace, service_name, repository_name, entity_name, fields)
      File.write("#{service_dir}/#{service_name}.cs", service_code)

      # Generate Repository
      repository_code = generate_dotnet_repository(namespace, repository_name, entity_name, fields)
      File.write("#{repository_dir}/#{repository_name}.cs", repository_code)
    end

    output = ""
    output << "Controllers gerados:\n".green
    controller_names.each { |name| output << "  - #{name}.cs\n".green }
    output << "\n".green
    output << "Services gerados:\n".green
    services.each { |name| output << "  - #{name}.cs\n".green }
    output << "\n".green
    output << "Repositories gerados:\n".green
    repositories.each { |name| output << "  - #{name}.cs\n".green }
    output << "\n".green
    output << "Total: #{controller_names.count} controllers, #{services.count} services, #{repositories.count} repositories gerados com sucesso!".green
    output
  end

  def generate_dotnet_controller(namespace, controller_name, service_name, entity_name, fields)
    route = entity_name.underscore.dasherize
    id_type = fields.key?("id") ? dotnet_type(fields["id"]) : "int"

    <<~CODE
      using Microsoft.AspNetCore.Mvc;
      using #{namespace}.Services;

      namespace #{namespace}.Controllers
      {
          [ApiController]
          [Route("api/#{route}")]
          public class #{controller_name} : ControllerBase
          {
              private readonly I#{service_name} _service;

              public #{controller_name}(I#{service_name} service)
              {
                  _service = service;
              }

              [HttpGet]
              public async Task<IActionResult> GetAll()
              {
                  var result = await _service.GetAllAsync();
                  return Ok(result);
              }

              [HttpGet("{id}")]
              public async Task<IActionResult> GetById(#{id_type} id)
              {
                  var result = await _service.GetByIdAsync(id);
                  if (result == null)
                      return NotFound();
                  return Ok(result);
              }

              [HttpPost]
              public async Task<IActionResult> Create([FromBody] #{entity_name} request)
              {
                  var result = await _service.CreateAsync(request);
                  return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
              }

              [HttpPut("{id}")]
              public async Task<IActionResult> Update(#{id_type} id, [FromBody] #{entity_name} request)
              {
                  await _service.UpdateAsync(id, request);
                  return NoContent();
              }

              [HttpDelete("{id}")]
              public async Task<IActionResult> Delete(#{id_type} id)
              {
                  await _service.DeleteAsync(id);
                  return NoContent();
              }
          }
      }
    CODE
  end

  def generate_dotnet_service(namespace, service_name, repository_name, entity_name, fields)
    <<~CODE
      using #{namespace}.Repositories;

      namespace #{namespace}.Services
      {
          public interface I#{service_name}
          {
              Task<IEnumerable<#{entity_name}>> GetAllAsync();
              Task<#{entity_name}> GetByIdAsync(int id);
              Task<#{entity_name}> CreateAsync(#{entity_name} entity);
              Task UpdateAsync(int id, #{entity_name} entity);
              Task DeleteAsync(int id);
          }

          public class #{service_name} : I#{service_name}
          {
              private readonly I#{repository_name} _repository;

              public #{service_name}(I#{repository_name} repository)
              {
                  _repository = repository;
              }

              public async Task<IEnumerable<#{entity_name}>> GetAllAsync()
              {
                  return await _repository.GetAllAsync();
              }

              public async Task<#{entity_name}> GetByIdAsync(int id)
              {
                  return await _repository.GetByIdAsync(id);
              }

              public async Task<#{entity_name}> CreateAsync(#{entity_name} entity)
              {
                  return await _repository.CreateAsync(entity);
              }

              public async Task UpdateAsync(int id, #{entity_name} entity)
              {
                  await _repository.UpdateAsync(id, entity);
              }

              public async Task DeleteAsync(int id)
              {
                  await _repository.DeleteAsync(id);
              }
          }
      }
    CODE
  end

  def generate_dotnet_repository(namespace, repository_name, entity_name, fields)
    <<~CODE
      using #{namespace}.Models;

      namespace #{namespace}.Repositories
      {
          public interface I#{repository_name}
          {
              Task<IEnumerable<#{entity_name}>> GetAllAsync();
              Task<#{entity_name}> GetByIdAsync(int id);
              Task<#{entity_name}> CreateAsync(#{entity_name} entity);
              Task UpdateAsync(int id, #{entity_name} entity);
              Task DeleteAsync(int id);
          }
      }
    CODE
  end

  def generate_node
    controller_names = []

    root_name = @json.is_a?(Array) ? "Root" : (@json.keys.first || "Root")
    root_name = root_name.to_s.classify

    if @json.is_a?(Array)
      process_object("Item", @json.first)
    else
      @json.each do |key, value|
        name = key.to_s.classify
        if value.is_a?(Hash) && !primitive?(value)
          process_object(name, value)
        end
      end
    end

    @classes.each do |class_name, fields|
      controller_name = "#{class_name.underscore}_controller"
      service_name = "#{class_name.underscore}_service"
      repository_name = "#{class_name.underscore}_repository"

      controller_dir = "#{@path}/controllers"
      service_dir = "#{@path}/services"
      repository_dir = "#{@path}/repositories"

      [controller_dir, service_dir, repository_dir].each do |dir|
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      end

      controller_code = generate_node_controller(controller_name, class_name)
      File.write("#{controller_dir}/#{controller_name}.js", controller_code)

      service_code = generate_node_service(service_name, class_name)
      File.write("#{service_dir}/#{service_name}.js", service_code)

      repository_code = generate_node_repository(repository_name, class_name, fields)
      File.write("#{repository_dir}/#{repository_name}.js", repository_code)

      controller_names << controller_name
    end

    output = ""
    output << "Controllers gerados:\n".green
    controller_names.each { |name| output << "  - #{name}.js\n".green }
    output << "\n".green
    output << "Services gerados:\n".green
    controller_names.each { |name| output << "  - #{name.sub('_controller', '_service')}.js\n".green }
    output << "\n".green
    output << "Repositories gerados:\n".green
    controller_names.each { |name| output << "  - #{name.sub('_controller', '_repository')}.js\n".green }
    output << "\n".green
    output << "Total: #{controller_names.count} controllers, #{controller_names.count} services, #{controller_names.count} repositories gerados com sucesso!".green
    output
  end

  def generate_node_controller(controller_name, class_name)
    route = class_name.underscore.dasherize
    <<~CODE
      const #{class_name.underscore}Service = require('../services/#{class_name.underscore}_service');

      class #{class_name}Controller {
        async getAll(req, res) {
          try {
            const result = await #{class_name.underscore}Service.getAll();
            return res.json(result);
          } catch (error) {
            return res.status(500).json({ error: error.message });
          }
        }

        async getById(req, res) {
          try {
            const result = await #{class_name.underscore}Service.getById(req.params.id);
            if (!result) return res.status(404).json({ error: 'Not found' });
            return res.json(result);
          } catch (error) {
            return res.status(500).json({ error: error.message });
          }
        }

        async create(req, res) {
          try {
            const result = await #{class_name.underscore}Service.create(req.body);
            return res.status(201).json(result);
          } catch (error) {
            return res.status(500).json({ error: error.message });
          }
        }

        async update(req, res) {
          try {
            const result = await #{class_name.underscore}Service.update(req.params.id, req.body);
            return res.json(result);
          } catch (error) {
            return res.status(500).json({ error: error.message });
          }
        }

        async delete(req, res) {
          try {
            await #{class_name.underscore}Service.delete(req.params.id);
            return res.status(204).send();
          } catch (error) {
            return res.status(500).json({ error: error.message });
          }
        }
      }

      module.exports = new #{class_name}Controller();
    CODE
  end

  def generate_node_service(service_name, class_name)
    <<~CODE
      const #{class_name.underscore}Repository = require('../repositories/#{class_name.underscore}_repository');

      class #{class_name}Service {
        async getAll() {
          return await #{class_name.underscore}Repository.getAll();
        }

        async getById(id) {
          return await #{class_name.underscore}Repository.getById(id);
        }

        async create(data) {
          return await #{class_name.underscore}Repository.create(data);
        }

        async update(id, data) {
          return await #{class_name.underscore}Repository.update(id, data);
        }

        async delete(id) {
          return await #{class_name.underscore}Repository.delete(id);
        }
      }

      module.exports = new #{class_name}Service();
    CODE
  end

  def generate_node_repository(repository_name, class_name, fields)
    <<~CODE
      // TODO: Configure your database connection for #{class_name}
      const db = null; // e.g., require('../database/connection');

      class #{class_name}Repository {
        async getAll() {
          // TODO: Implement database query
          throw new Error('Not implemented');
        }

        async getById(id) {
          // TODO: Implement database query
          throw new Error('Not implemented');
        }

        async create(data) {
          // Expected fields: #{fields.keys.join(', ')}
          // TODO: Implement database insert
          throw new Error('Not implemented');
        }

        async update(id, data) {
          // TODO: Implement database update
          throw new Error('Not implemented');
        }

        async delete(id) {
          // TODO: Implement database delete
          throw new Error('Not implemented');
        }
      }

      module.exports = new #{class_name}Repository();
    CODE
  end

  def generate_python
    controller_names = []

    if @json.is_a?(Array)
      process_object("Item", @json.first)
    else
      @json.each do |key, value|
        name = key.to_s.classify
        if value.is_a?(Hash) && !primitive?(value)
          process_object(name, value)
        end
      end
    end

    @classes.each do |class_name, fields|
      controller_name = "#{class_name.underscore}_controller"
      service_name = "#{class_name.underscore}_service"
      repository_name = "#{class_name.underscore}_repository"

      controller_dir = "#{@path}/controllers"
      service_dir = "#{@path}/services"
      repository_dir = "#{@path}/repositories"

      [controller_dir, service_dir, repository_dir].each do |dir|
        FileUtils.mkdir_p(dir)
      end

      controller_code = generate_python_controller(controller_name, class_name)
      File.write("#{controller_dir}/#{controller_name}.py", controller_code)

      service_code = generate_python_service(service_name, class_name)
      File.write("#{service_dir}/#{service_name}.py", service_code)

      repository_code = generate_python_repository(repository_name, class_name, fields)
      File.write("#{repository_dir}/#{repository_name}.py", repository_code)

      controller_names << controller_name
    end

    output = ""
    output << "Controllers gerados:\n".green
    controller_names.each { |name| output << "  - #{name}.py\n".green }
    output << "\n".green
    output << "Services gerados:\n".green
    controller_names.each { |name| output << "  - #{name.sub('_controller', '_service')}.py\n".green }
    output << "\n".green
    output << "Repositories gerados:\n".green
    controller_names.each { |name| output << "  - #{name.sub('_controller', '_repository')}.py\n".green }
    output << "\n".green
    output << "Total: #{controller_names.count} controllers, #{controller_names.count} services, #{controller_names.count} repositories gerados com sucesso!".green
    output
  end

  def generate_python_controller(controller_name, class_name)
    <<~CODE
      from fastapi import APIRouter, HTTPException
      from .services.#{class_name.underscore}_service import #{class_name}Service

      router = APIRouter(prefix="/#{class_name.underscore.dasherize}", tags=["#{class_name}"])
      service = #{class_name}Service()


      @router.get("/")
      async def get_all():
          try:
              return await service.get_all()
          except Exception as e:
              raise HTTPException(status_code=500, detail=str(e))


      @router.get("/{item_id}")
      async def get_by_id(item_id: int):
          try:
              result = await service.get_by_id(item_id)
              if not result:
                  raise HTTPException(status_code=404, detail="Not found")
              return result
          except HTTPException:
              raise
          except Exception as e:
              raise HTTPException(status_code=500, detail=str(e))


      @router.post("/", status_code=201)
      async def create(data: dict):
          try:
              return await service.create(data)
          except Exception as e:
              raise HTTPException(status_code=500, detail=str(e))


      @router.put("/{item_id}")
      async def update(item_id: int, data: dict):
          try:
              return await service.update(item_id, data)
          except Exception as e:
              raise HTTPException(status_code=500, detail=str(e))


      @router.delete("/{item_id}", status_code=204)
      async def delete(item_id: int):
          try:
              await service.delete(item_id)
          except Exception as e:
              raise HTTPException(status_code=500, detail=str(e))
    CODE
  end

  def generate_python_service(service_name, class_name)
    <<~CODE
      from .repositories.#{class_name.underscore}_repository import #{class_name}Repository


      class #{class_name}Service:
          def __init__(self):
              self.repository = #{class_name}Repository()

          async def get_all(self):
              return await self.repository.get_all()

          async def get_by_id(self, id: int):
              return await self.repository.get_by_id(id)

          async def create(self, data: dict):
              return await self.repository.create(data)

          async def update(self, id: int, data: dict):
              return await self.repository.update(id, data)

          async def delete(self, id: int):
              return await self.repository.delete(id)
    CODE
  end

  def generate_python_repository(repository_name, class_name, fields)
    <<~CODE
      class #{class_name}Repository:
          # TODO: Configure database connection
          def __init__(self):
              pass

          async def get_all(self):
              # TODO: Implement database query
              raise NotImplementedError

          async def get_by_id(self, id: int):
              # TODO: Implement database query
              raise NotImplementedError

          async def create(self, data: dict):
              # Expected fields: #{fields.keys.join(', ')}
              # TODO: Implement database insert
              raise NotImplementedError

          async def update(self, id: int, data: dict):
              # TODO: Implement database update
              raise NotImplementedError

          async def delete(self, id: int):
              # TODO: Implement database delete
              raise NotImplementedError
    CODE
  end

  def generate_typescript
    controller_names = []

    if @json.is_a?(Array)
      process_object("Item", @json.first)
    else
      @json.each do |key, value|
        name = key.to_s.classify
        if value.is_a?(Hash) && !primitive?(value)
          process_object(name, value)
        end
      end
    end

    @classes.each do |class_name, fields|
      controller_name = "#{class_name}Controller"
      service_name = "#{class_name}Service"
      repository_name = "#{class_name}Repository"

      controller_dir = "#{@path}/controllers"
      service_dir = "#{@path}/services"
      repository_dir = "#{@path}/repositories"

      [controller_dir, service_dir, repository_dir].each do |dir|
        FileUtils.mkdir_p(dir)
      end

      controller_code = generate_ts_controller(controller_name, class_name)
      File.write("#{controller_dir}/#{controller_name}.ts", controller_code)

      service_code = generate_ts_service(service_name, class_name)
      File.write("#{service_dir}/#{service_name}.ts", service_code)

      repository_code = generate_ts_repository(repository_name, class_name, fields)
      File.write("#{repository_dir}/#{repository_name}.ts", repository_code)

      controller_names << controller_name
    end

    output = ""
    output << "Controllers gerados:\n".green
    controller_names.each { |name| output << "  - #{name}.ts\n".green }
    output << "\n".green
    output << "Services gerados:\n".green
    controller_names.each { |name| output << "  - #{name.sub('Controller', 'Service')}.ts\n".green }
    output << "\n".green
    output << "Repositories gerados:\n".green
    controller_names.each { |name| output << "  - #{name.sub('Controller', 'Repository')}.ts\n".green }
    output << "\n".green
    output << "Total: #{controller_names.count} controllers, #{controller_names.count} services, #{controller_names.count} repositories gerados com sucesso!".green
    output
  end

  def generate_ts_controller(controller_name, class_name)
    <<~CODE
      import { Request, Response } from 'express';
      import { #{class_name}Service } from '../services/#{class_name}Service';

      const service = new #{class_name}Service();

      export class #{controller_name} {
        async getAll(req: Request, res: Response): Promise<void> {
          try {
            const result = await service.getAll();
            res.json(result);
          } catch (error) {
            res.status(500).json({ error: (error as Error).message });
          }
        }

        async getById(req: Request, res: Response): Promise<void> {
          try {
            const result = await service.getById(Number(req.params.id));
            if (!result) {
              res.status(404).json({ error: 'Not found' });
              return;
            }
            res.json(result);
          } catch (error) {
            res.status(500).json({ error: (error as Error).message });
          }
        }

        async create(req: Request, res: Response): Promise<void> {
          try {
            const result = await service.create(req.body);
            res.status(201).json(result);
          } catch (error) {
            res.status(500).json({ error: (error as Error).message });
          }
        }

        async update(req: Request, res: Response): Promise<void> {
          try {
            const result = await service.update(Number(req.params.id), req.body);
            res.json(result);
          } catch (error) {
            res.status(500).json({ error: (error as Error).message });
          }
        }

        async delete(req: Request, res: Response): Promise<void> {
          try {
            await service.delete(Number(req.params.id));
            res.status(204).send();
          } catch (error) {
            res.status(500).json({ error: (error as Error).message });
          }
        }
      }
    CODE
  end

  def generate_ts_service(service_name, class_name)
    <<~CODE
      import { #{class_name}Repository } from '../repositories/#{class_name}Repository';

      export class #{service_name} {
        private repository: #{class_name}Repository;

        constructor() {
          this.repository = new #{class_name}Repository();
        }

        async getAll() {
          return this.repository.getAll();
        }

        async getById(id: number) {
          return this.repository.getById(id);
        }

        async create(data: any) {
          return this.repository.create(data);
        }

        async update(id: number, data: any) {
          return this.repository.update(id, data);
        }

        async delete(id: number) {
          return this.repository.delete(id);
        }
      }
    CODE
  end

  def generate_ts_repository(repository_name, class_name, fields)
    <<~CODE
      // TODO: Configure database connection for #{class_name}
      let db: any = null;

      export class #{repository_name} {
        async getAll() {
          // TODO: Implement database query
          throw new Error('Not implemented');
        }

        async getById(id: number) {
          // TODO: Implement database query
          throw new Error('Not implemented');
        }

        async create(data: any) {
          // Expected fields: #{fields.keys.join(', ')}
          // TODO: Implement database insert
          throw new Error('Not implemented');
        }

        async update(id: number, data: any) {
          // TODO: Implement database update
          throw new Error('Not implemented');
        }

        async delete(id: number) {
          // TODO: Implement database delete
          throw new Error('Not implemented');
        }
      }
    CODE
  end

  def process_object(name, obj)
    fields = {}
    obj.each do |key, value|
      type = resolve_type(key, value, obj)
      fields[key] = type
    end
    @classes[name] = fields
  end

  def resolve_type(key, value, parent = nil)
    case value
    when Hash
      "object"
    when Array
      if value.empty?
        "array"
      elsif value.first.is_a?(Hash)
        "array"
      else
        "array"
      end
    when String
      "string"
    when Integer
      "int"
    when Float
      "float"
    when true, false
      "bool"
    when nil
      "object"
    else
      "object"
    end
  end

  def primitive?(obj)
    !obj.is_a?(Hash) && !obj.is_a?(Array)
  end

  def dotnet_type(type)
    case type
    when "int", "long"
      "int"
    when "float", "double", "decimal"
      "decimal"
    when "string"
      "string"
    when "bool"
      "bool"
    when "DateTime", "date"
      "DateTime"
    else
      "int"
    end
  end
end
