class ImportBillettoEventsJob < ApplicationJob
  queue_as :default

  retry_on Billetto::Error,
           wait: ->(executions) { 2**executions },
           attempts: 5
  discard_on Billetto::AuthenticationError
  def perform
    ImportBillettoEvents.new.call
  end
end