class Connector::TestConnectionJob < ApplicationJob
  queue_as :default

  def perform(connector_id)
    Connector.find(connector_id).adapter.test_connection!
  end
end
