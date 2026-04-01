Gem::Specification.new do |spec|
  spec.name          = "dto-cli"
  spec.version       = "0.1.0"
  spec.summary       = "CLI para gerar DTOs e projetos"
  spec.authors       = ["Lucas Almeida"]

  spec.files         = Dir[
    "lib/**/*",
    "bin/*",
    "templates/**/*"
  ]

  spec.executables   = ["dto-cli-dev"]
  spec.require_paths = ["lib"]

  spec.add_dependency "thor"
  spec.add_dependency "faraday"
  spec.add_dependency "activesupport"
end