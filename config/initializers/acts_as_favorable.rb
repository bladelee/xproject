# Be sure to restart your server when you modify this file.

# For development and non-eager load mode, we need to register the acts_as_favorable models manually
# as no eager loading takes place
Rails.application.config.after_initialize do
  puts "------------------Registering acts_as_favorable models"
  OpenProject::Acts::Favorable::Registry
    .add(Project)
end
