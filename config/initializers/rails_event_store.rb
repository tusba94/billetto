require "rails_event_store"
require "ruby_event_store/active_record/event"
require "aggregate_root"
require "arkency/command_bus"

Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::JSONClient.new
  Rails.configuration.command_bus = Arkency::CommandBus.new

  Rails.configuration.command_bus.tap do |bus|
    bus.register(
      Voting::Commands::UpvoteEvent,
      Voting::Commands::UpvoteEventHandler.new
    )
    bus.register(
    Voting::Commands::DownvoteEvent,
    Voting::Commands::DownvoteEventHandler.new
    )
  end
  
  # Use AggregateRoot::Repository with explicit event store injection, e.g.:
  #
  #   repository = AggregateRoot::Repository.new(Rails.configuration.event_store)
  #   repository.with_aggregate(Order.new(order_id), "Order$#{order_id}") do |order|
  #     order.submit
  #   end

  # Subscribe event handlers below
  Rails.configuration.event_store.tap do |store|
    # store.subscribe(InvoiceReadModel.new, to: [InvoicePrinted])
    # store.subscribe(lambda { |event| SendOrderConfirmation.new.call(event) }, to: [OrderSubmitted])
    # store.subscribe_to_all_events(lambda { |event| Rails.logger.info(event.event_type) })

    store.subscribe_to_all_events(RailsEventStore::LinkByEventType.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)
    store.subscribe(
      Voting::ReadModels::EventVoteStateProjector.new,
      to: [
        Voting::EventUpvoted,
        Voting::EventDownvoted
      ])
    end

  # Register command handlers below
  # Rails.configuration.command_bus.tap do |bus|
  #   bus.register(PrintInvoice, Invoicing::OnPrint.new)
  #   bus.register(SubmitOrder, ->(cmd) { Ordering::OnSubmitOrder.new.call(cmd) })
  # end
end
