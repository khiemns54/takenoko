$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "takenoko/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "takenoko"
  s.version     = Takenoko::VERSION
  s.authors     = ["KhiemNS"]
  s.email       = ["khiemns54@gmail.com"]
  s.homepage    = "https://github.com/khiemns54/takenoko/tree/release/0.3.0"
  s.summary     = "Import data from google spreadsheet to database or files for Rails"
  s.description = "Rails: Import data from google spreadsheet to database or files, download files that attach to rows"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.files += Dir.glob("tasks/**/*")
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 4.0.13"
  s.add_dependency "google-api-client", "0.11"
  s.add_dependency "google_drive"
  s.add_development_dependency "sqlite3"
end
