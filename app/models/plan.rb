class Plan < ApplicationRecord
  FEATURES = {
    "starter"    => %w[agent_engine http_connector knowledge_base basic_logs],
    "growth"     => %w[agent_engine http_connector sql_connector knowledge_base
                       tool_engine advanced_logs webhooks streaming],
    "enterprise" => %w[agent_engine http_connector sql_connector saas_connectors
                       knowledge_base tool_engine advanced_logs webhooks
                       streaming api_access custom_models sla_support]
  }.freeze

  has_many :subscriptions

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true).order(:price_cents) }

  def unlimited?
    analyses_per_month.nil?
  end

  def feature?(name)
    FEATURES[slug]&.include?(name.to_s)
  end

  def price_display
    return "Sob consulta" if price_cents.zero?
    "R$ #{format("%.0f", price_cents / 100.0)}/mês"
  end
end
