Gem::Specification.new do |s|
  s.name        = "openproject-people_resource"
  s.version     = "1.0.0"
  s.authors     = "OpenProject"
  s.email       = "info@openproject.com"
  s.summary     = "OpenProject People Resource"
  s.description = "This plugin allows creating custom cost reports with filtering and grouping created by the OpenProject Costs plugin"

  s.files       = Dir["{app,config,db,lib}/**/*", "README.md"]

  #s.add_dependency "costs"
  s.metadata["rubygems_mfa_required"] = "true"
end
