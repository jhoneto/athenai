class Rack::Attack
  throttle("api/requests_per_api_key", limit: 300, period: 1.minute) do |request|
    next unless request.path.start_with?("/api/")

    token = request.get_header("HTTP_AUTHORIZATION")&.delete_prefix("Bearer ")
    token&.split(".", 2)&.first
  end
end
