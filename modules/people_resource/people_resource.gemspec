Gem::Specification.new do |s|
  s.name        = "people_resource"
  s.version     = "1.0.0"
  s.authors     = "xProject"
  s.email       = "info@xproject.com"
  s.summary     = "xProject People Resource"
  s.description = "This plugin allows creating custom cost reports with filtering and grouping created by the XProject plugin"

  s.files       = Dir["{app,config,db,lib}/**/*", "README.md"]

  #s.add_dependency "costs"
  # s.add_dependency "vcard"
  s.add_dependency "redmineup"
  s.metadata["rubygems_mfa_required"] = "true"
end
