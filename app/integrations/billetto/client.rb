require "net/http"

module Billetto
  class Client
    BASE_URL = "https://billetto.dk/api/v3/public/events"

    def initialize(api_keypair: ENV["BILLETTO_API_KEYPAIR"])
      @api_keypair = api_keypair
    end

    def fetch_events(limit: 10)
      uri = URI(BASE_URL)
      uri.query = URI.encode_www_form(limit: limit)

      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"
      request["Api-Keypair"] = @api_keypair if @api_keypair.present?

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: true
      ) do |http|
        http.request(request)
      end

      handle_response(response)
    rescue Billetto::Error
      raise
    rescue StandardError => e
      raise Billetto::Error, "Failed to fetch events: #{e.message}"
    end

    private

    def handle_response(response)
        case response
        when Net::HTTPSuccess
            JSON.parse(response.body)
        when Net::HTTPUnauthorized
            raise Billetto::AuthenticationError,
            "Billetto API authentication failed: #{response.body}"
        else
            raise Billetto::Error,
            "Billetto API returned #{response.code}: #{response.body}"
        end
    end

    def parse_events(body)
      data = JSON.parse(body)

      data.map do |event|
        {
          billetto_id: event["id"],
          title: event["name"],
          description: event["description"],
          starts_at: parse_time(event["start_date"]),
          ends_at: parse_time(event["end_date"]),
          image_url: event.dig("image", "url"),
          metadata: event
        }
      end
    rescue JSON::ParserError => e
      raise Billetto::Error, "Invalid Billetto response: #{e.message}"
    end

    def parse_time(value)
      return if value.blank?

      Time.zone.parse(value)
    end
  end
end