class Connector::ImportOpenApiJob < ApplicationJob
  queue_as :default

  def perform(connector_id)
    Connector::OpenApiImporter.new(Connector.find(connector_id)).call
  end
end
