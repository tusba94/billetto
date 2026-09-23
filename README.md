# Billetto Event Voting API

A Ruby on Rails application that imports events from the Billetto API, exposes them through a JSON API, and allows authenticated users to upvote or downvote events.

The application uses Rails Event Store for voting domain events, Clerk for authentication, and Sidekiq for asynchronous Billetto imports.

## Tech Stack

- Ruby 3.4.5
- Rails 8.1.3.1
- PostgreSQL
- Redis
- Rails Event Store 3.1.0
- Sidekiq 8.1.7
- Sidekiq Cron
- Clerk
- Minitest

## Architecture

The application separates external integrations, domain logic, commands, event storage, and read models.

```text
                         Billetto API
                              |
                              v
                    Billetto Integration
                         (ACL)
                              |
                              v
                    ImportBillettoEvents
                              |
                              v
                         Event Model
                              |
                              v
                       Events API


       User
        |
        v
   Clerk Authentication
        |
        v
   Voting Controller
        |
        v
    Command Bus
        |
        +-------------------+
        |                   |
        v                   v
  UpvoteEvent        DownvoteEvent
        |                   |
        +---------+---------+
                  |
                  v
          Rails Event Store
                  |
                  v
        EventVoteStateProjector
                  |
                  v
          event_vote_states
```

## Event Import

Billetto events are imported asynchronously.

The flow is:

```text
Sidekiq Cron
     |
     | every 5 minutes
     v
ImportBillettoEventsJob
     |
     v
ImportBillettoEvents
     |
     v
Billetto::Client
     |
     v
Billetto API
```

The import service uses the Billetto event ID as the external identifier.

A unique database index on `events.billetto_id` prevents duplicate records.

The import uses:

```ruby
Event.find_or_initialize_by(billetto_id: ...)
```

so running the import repeatedly is idempotent.

### Billetto Integration Boundary

The Billetto API is isolated behind an integration boundary under:

```text
app/integrations/billetto/
```

The integration contains:

- `Billetto::Client` - real API adapter
- `Billetto::Error` - integration-specific errors
- `Billetto::FakeClient` - deterministic fake client for development/tests

The adapter normalizes external Billetto data into the application's internal event representation before it reaches the application layer.

### Error handling

Billetto API errors are represented by custom exceptions.

Temporary Billetto errors are retried by Active Job:

```ruby
retry_on Billetto::Error,
         wait: ->(executions) { 2**executions },
         attempts: 5
```

Authentication errors are discarded:

```ruby
discard_on Billetto::AuthenticationError
```

This prevents invalid credentials from causing repeated retries.

## Voting

Voting is implemented using Rails Event Store.

The application exposes:

```text
POST /events/:event_id/upvote
POST /events/:event_id/downvote
```

Only authenticated Clerk users can vote.

The controller creates a command and sends it through the command bus:

```text
Controller
    |
    v
Command
    |
    v
Command Bus
    |
    v
Command Handler
    |
    v
Domain Event
    |
    v
Rails Event Store
```

The domain events are:

```text
Voting::EventUpvoted
Voting::EventDownvoted
```

Each event contains:

- `event_id`
- `user_id`

The `user_id` is the Clerk user ID, which provides traceability without requiring a local users table.

### Command Bus

Voting commands are dispatched through the command bus rather than invoking command handlers directly.

The current commands are:

```text
Voting::Commands::UpvoteEvent
Voting::Commands::DownvoteEvent
```

Each command carries the internal event ID and authenticated Clerk user ID.

The command handlers are responsible for creating and publishing the corresponding domain event to Rails Event Store.

## Vote Read Model

The current voting state is projected into:

```text
event_vote_states
```

Schema:

```text
event_id
user_id
vote
```

The table has a unique constraint on:

```text
event_id + user_id
```

This represents the user's current vote for an event.

For example:

```text
event_id | user_id   | vote
---------+-----------+------
1        | user_123  | up
1        | user_456  | down
```

The event store remains the source of truth for voting history, while `event_vote_states` provides an efficient representation of the current state.

A user can have one current vote per event. If the user changes from upvote to downvote, the event history remains immutable while the read model is updated to the latest state.

### Projection

The projection listens to:

```text
Voting::EventUpvoted
Voting::EventDownvoted
```

and updates `event_vote_states`.

The projection can also be rebuilt from the event stream using:

```text
Voting::ReadModels::RebuildEventVoteStates
```

This allows the read model to be reconstructed from persisted domain events.

## Authentication

Clerk is used for user authentication.

Authentication is handled by the Clerk Rails SDK.

The authentication page is available at:

```text
GET /auth
```

The current authenticated Clerk user can be checked through:

```text
GET /auth/me
```

Voting endpoints return:

```text
401 Unauthorized
```

when no authenticated Clerk user is present.

The browser flow has been manually verified:

1. Open `/auth`
2. Sign up/login with Clerk
3. Authenticate successfully
4. Submit an upvote/downvote request
5. Verify the request succeeds
6. Verify the corresponding event appears in Rails Event Store
7. Verify the read model is updated

## API

### List events

```http
GET /events
```

Returns events ordered by start time.

Example:

```json
[
  {
    "id": 1,
    "title": "Live Music Festival",
    "description": "A live music event featuring multiple artists.",
    "starts_at": "2026-10-10T18:00:00Z",
    "ends_at": "2026-10-10T23:00:00Z",
    "image_url": "https://example.com/events/music-festival.jpg",
    "upvotes": 3,
    "downvotes": 2
  }
]
```

### Show an event

```http
GET /events/:id
```

Returns a single event with its voting counts.

### Upvote

```http
POST /events/:event_id/upvote
```

Requires Clerk authentication.

### Downvote

```http
POST /events/:event_id/downvote
```

Requires Clerk authentication.

## Rails Event Store Browser

In development, Rails Event Store Browser is available at:

```text
/res
```

This can be used to inspect persisted domain events.

The browser is mounted only in the development environment.

## Database

The application uses PostgreSQL.

### events

Stores normalized event data received from Billetto.

Important fields include:

- `id`
- `billetto_id`
- `title`
- `description`
- `starts_at`
- `ends_at`
- `image_url`
- `metadata`

`billetto_id` has a unique database index.

### event_vote_states

Stores the current vote state for each user/event combination.

Important fields include:

- `event_id`
- `user_id`
- `vote`

There is a unique database index on:

```text
event_id + user_id
```

## Configuration

The application uses environment variables for credentials.

Required configuration:

```text
CLERK_SECRET_KEY=...
CLERK_PUBLISHABLE_KEY=...
BILLETTO_API_KEY=...
```

Do not commit credentials to source control.

The project `.gitignore` excludes `.env*` files.

### Billetto credentials

The real Billetto API client requires valid Billetto API credentials.

For local development and automated tests, the application also contains:

```text
Billetto::FakeClient
```

which returns normalized sample events without requiring Billetto credentials.

This allows the import service and related tests to run without making requests to the external Billetto API.

## Requirements

You will need:

- Ruby 3.4.5
- PostgreSQL
- Redis
- Bundler

## Setup

Install dependencies:

```bash
bundle install
```

Create and prepare the database:

```bash
bin/rails db:create
bin/rails db:migrate
```

Configure the required environment variables.

Start Redis:

```bash
redis-server
```

Verify Redis:

```bash
redis-cli ping
```

Expected response:

```text
PONG
```

Start Rails:

```bash
bin/rails server
```

Start Sidekiq in another terminal:

```bash
bundle exec sidekiq
```

The Sidekiq process loads the recurring schedule from:

```text
config/sidekiq/schedule.yml
```

## Running Tests

Run the complete test suite with test Clerk credentials:

```bash
CLERK_SECRET_KEY=sk_test_dummy CLERK_PUBLISHABLE_KEY=pk_test_dummy bin/rails test
```

The test suite covers:

- Event model behavior
- Vote state validation
- Voting domain events
- Vote projection
- Event API
- Authentication restrictions
- Billetto event importing
- Idempotent importing
- Billetto import job

Current test suite:

```text
14 runs
39 assertions
0 failures
0 errors
0 skips
```

## Background Jobs and Scheduling

Billetto imports are scheduled every five minutes using Sidekiq Cron.

Schedule:

```text
*/5 * * * *
```

The scheduler enqueues:

```text
ImportBillettoEventsJob
```

The job then executes the import service asynchronously.

The schedule is defined in:

```text
config/sidekiq/schedule.yml
```

The Sidekiq configuration is initialized through:

```text
config/initializers/sidekiq.rb
```

The job can also be triggered manually:

```bash
bin/rails runner 'ImportBillettoEventsJob.perform_later'
```

### Job execution flow

```text
Sidekiq Cron
      |
      | every 5 minutes
      v
ImportBillettoEventsJob
      |
      v
ImportBillettoEvents
      |
      v
Billetto::Client
```

The job is intentionally kept small. Scheduling and asynchronous execution are handled by Sidekiq, while import behavior remains in the service object.

## Development Notes

The project follows a domain-oriented structure:

```text
app/
├── controllers/
│   ├── application_controller.rb
│   ├── auth_controller.rb
│   ├── events_controller.rb
│   └── voting_controller.rb
│
├── domain/
│   └── voting/
│       ├── commands/
│       │   ├── upvote_event.rb
│       │   ├── upvote_event_handler.rb
│       │   ├── downvote_event.rb
│       │   └── downvote_event_handler.rb
│       │
│       ├── read_models/
│       │   ├── event_vote_state_projector.rb
│       │   └── rebuild_event_vote_states.rb
│       │
│       ├── event_upvoted.rb
│       └── event_downvoted.rb
│
├── integrations/
│   └── billetto/
│       ├── client.rb
│       ├── error.rb
│       └── fake_client.rb
│
└── jobs/
    └── import_billetto_events_job.rb
```

### Controllers

Controllers are intentionally thin.

For example, the voting controller:

1. Verifies authentication.
2. Validates that the requested event exists.
3. Creates the appropriate command.
4. Sends the command through the command bus.

Business behavior is kept outside the controller.

### Integrations

External Billetto API behavior is isolated under:

```text
app/integrations/billetto
```

This provides an anti-corruption layer between the external API representation and the application's internal representation.

The rest of the application does not need to know about Billetto-specific API response structures.

### Domain Events

Voting actions are represented as immutable domain events.

The event store preserves the history of those actions, while projections provide query-friendly state.

This separation makes it possible to rebuild the current voting state from the event history.

## Design Decisions

### Why Rails Event Store?

Voting is represented as domain events so that the history of voting actions remains available and traceable.

This also allows read models to be rebuilt from the event history.

### Why a separate import service?

The Sidekiq job is responsible for asynchronous execution, while `ImportBillettoEvents` contains the actual import logic.

This keeps the job small and makes the import behavior easier to test independently.

### Why use Billetto IDs separately from local event IDs?

Billetto is an external system, so its identifiers are treated as external identifiers.

The application uses its own database primary key for internal relationships and stores the Billetto identifier in:

```text
events.billetto_id
```

This prevents external identifiers from becoming tightly coupled to internal database relationships.

### Why no local users table?

Clerk is the authentication provider and supplies the user identity.

The voting read model stores the Clerk user ID directly, avoiding unnecessary duplication of authentication data.

### Why use a read model for voting state?

The Rails Event Store contains the immutable voting history.

`event_vote_states` provides a query-friendly representation of the latest vote for each user/event combination.

This avoids replaying the entire event stream every time the current voting state is required.

### Why use a command bus?

Commands are dispatched through a central command bus rather than directly invoking handlers.

This provides a single boundary for command execution and keeps controllers decoupled from command-handler implementation details.

## Manual Verification Flow

A reviewer can verify the main functionality with the following flow.

### 1. Start dependencies

```bash
redis-server
```

```bash
bundle exec sidekiq
```

### 2. Start Rails

```bash
bin/rails server
```

### 3. Check events API

Open:

```text
http://localhost:3000/events
```

### 4. Authenticate

Open:

```text
http://localhost:3000/auth
```

Sign up or log in through Clerk.

### 5. Check authenticated user

Open:

```text
http://localhost:3000/auth/me
```

An authenticated response should contain the Clerk user ID.

### 6. Vote

Send:

```http
POST /events/:event_id/upvote
```

or:

```http
POST /events/:event_id/downvote
```

### 7. Inspect the event

In development, open:

```text
http://localhost:3000/res
```

The corresponding:

```text
Voting::EventUpvoted
```

or:

```text
Voting::EventDownvoted
```

event should be present.

### 8. Verify the read model

The corresponding `event_vote_states` record should contain the event ID, Clerk user ID, and current vote.

## Future Enhancements

Possible future improvements include:

- A dedicated `EventVoteCounts` read model for precomputed upvote/downvote totals.
- Returning the authenticated user's current vote in the event API.
- Pagination for the events endpoint.
- Monitoring and metrics for Billetto imports and background jobs.
- More extensive system/browser tests around the complete Clerk authentication flow.
- Production deployment configuration and health monitoring.
- Additional observability around event-store projections and rebuild operations.
- Handling multiple Billetto API pages during scheduled imports.
- Rate-limit/backoff handling based on Billetto API responses.
# billetto
