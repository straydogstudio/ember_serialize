$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ember_serialize/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ember_serialize"
  s.version     = EmberSerialize::VERSION
  s.authors     = ["Noel Peden"]
  s.email       = ["noel@peden.biz"]
  s.homepage    = "https://github.com/straydogstudio/ember_serialize"
  s.summary     = "Generate ember models from Rails serializers"
  s.description = "Generate ember models from Rails serializers. Uses introspection to find correct associations, allows ignores, retains any customization."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.1.2"
  s.add_dependency "active_model_serializers", '~> 0.8.1'

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "ember-rails"
  s.add_development_dependency "pry"
end
