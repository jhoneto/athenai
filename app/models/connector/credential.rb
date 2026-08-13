class Connector::Credential < ApplicationRecord
  self.table_name = "connector_credentials"

  belongs_to :connector

  serialize :encrypted_secrets, coder: JSON
  encrypts :encrypted_secrets

  validates :encrypted_secrets, presence: true
end
