class Connector::Adapters::Http < Connector::Adapters::Base
  TIMEOUT = 10

  def test_connection!
    response = connection.get(relative_path(@connector.config["health_path"]))
    @connector.update!(status: response.success? ? :connected : :error)
  end

  def call(action, params)
    definition = action.definition
    path, remaining_params = interpolate_path(definition["path"], params)
    response = connection.public_send(definition["method"].downcase, path, remaining_params)
    raise ExecutionError, "HTTP #{response.status}" unless response.success?

    response.body
  end

  private

  def interpolate_path(path, params)
    remaining = params.dup
    path = path.gsub(/\{(\w+)\}/) do
      key = Regexp.last_match(1)
      raise ExecutionError, "missing path parameter: #{key}" unless remaining.key?(key)
      remaining.delete(key).to_s
    end
    [ relative_path(path), remaining ]
  end

  # Faraday/URI treats a leading "/" as absolute to the host root, which would
  # drop any path prefix already present in config["base_url"] (e.g. "/v2").
  def relative_path(path)
    path.to_s.delete_prefix("/")
  end

  def connection
    Faraday.new(url: @connector.config["base_url"]) do |f|
      f.request :json
      f.response :json
      f.options.timeout = TIMEOUT
      f.headers["Authorization"] = "Bearer #{@credential&.encrypted_secrets&.dig('api_key')}" if @credential
    end
  end
end
