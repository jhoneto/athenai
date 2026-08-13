class Connector::OpenApiImporter
  def initialize(connector)
    @connector = connector
  end

  def call
    spec = fetch_spec
    spec["paths"].each do |path, operations|
      operations.each do |method, operation|
        next unless %w[get post put patch delete].include?(method)

        @connector.actions.find_or_create_by!(name: operation["operationId"] || "#{method}_#{path}") do |action|
          action.kind = :http_call
          action.description = operation["summary"]
          action.input_schema = build_input_schema(operation)
          action.definition = { "method" => method, "path" => path }
        end
      end
    end
  end

  private

  def fetch_spec
    JSON.parse(Faraday.get(@connector.config["spec_url"]).body)
  end

  def build_input_schema(operation)
    properties = (operation["parameters"] || []).index_by { |p| p["name"] }
      .transform_values { |p| p["schema"] || { "type" => "string" } }

    { "type" => "object", "properties" => properties }
  end
end
