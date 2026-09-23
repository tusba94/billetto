require "sidekiq"
require "sidekiq/cron"

if defined?(Sidekiq::Cron)
  Sidekiq::Cron::Job.load_from_hash(
    YAML.load_file(Rails.root.join("config/sidekiq/schedule.yml"))
  )
end