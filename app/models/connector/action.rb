class Connector::Action < ApplicationRecord
  self.table_name = "connector_actions"

  belongs_to :connector

  enum :kind, { query: 0, http_call: 1, graphql_call: 2, file_search: 3 }

  validates :name, presence: true, uniqueness: { scope: :connector_id }
  validates :input_schema, :definition, presence: true
end
