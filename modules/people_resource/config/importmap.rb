# Pin npm packages by running ./bin/importmap

# pin "app/javascript/application2", to: "application2.js"
# pin "application",  to: "/assets/application-import.js"
# pin "application", preload: true
#pin "application", to: "application.js" 
pin "application",  to: "application2.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
# pin_all_from "app/javascript/controllers", under: "controllers", to: "controllers" 
# pin_all_from Rails.root.join("app/javascript/controllers"), under: "controllers", to: "controllers" 
pin_all_from File.expand_path("../app/javascript/controllers", __dir__), under: "controllers", to: "controllers" 
