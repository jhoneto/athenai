class Connector < ApplicationRecord
  belongs_to :account
  has_one  :credential, class_name: "Connector::Credential", dependent: :destroy
  has_many :actions, class_name: "Connector::Action", dependent: :destroy

  # Enum propositalmente amplo desde já para não exigir migration quando cada adapter for priorizado.
  # Fase 1 (Planos 5/6) implementa apenas: rest, openapi, postgres.
  # Demais valores ficam reservados para fase futura — ver doc/architecture.md §4.3.
  enum :kind, {
    postgres: 0, mysql: 1, sqlserver: 2, oracle: 3,
    rest: 4, graphql: 5, openapi: 6,
    gmail: 7, microsoft365: 8, google_drive: 9, sharepoint: 10, s3: 11
  }
  enum :status, { pending: 0, connected: 1, error: 2, disabled: 3 }

  validates :name, presence: true, uniqueness: { scope: :account_id }

  # "rest" e "openapi" não convertem para o nome de classe do adapter via #camelize
  # (o adapter REST genérico chama-se Http; a spec OpenAPI só gera Actions do tipo http_call).
  ADAPTER_CLASS_NAMES = { "rest" => "Http", "openapi" => "OpenApi" }.freeze

  def adapter
    class_name = ADAPTER_CLASS_NAMES.fetch(kind, kind.camelize)
    "Connector::Adapters::#{class_name}".constantize.new(self)
  end
end
