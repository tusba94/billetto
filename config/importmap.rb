# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@clerk/clerk-js", to: "@clerk--clerk-js.js" # @6.32.1
pin "clerk", to: "clerk.js"
pin "voting", to: "voting.js"
