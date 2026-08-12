class Llm::Model < ApplicationRecord
  self.table_name = "llm_models"

  SUPPORTED_PROVIDERS = %w[openai anthropic gemini].freeze

  acts_as_model chats: :sessions, chat_class: "Session"

  has_many :llm_profiles, dependent: :nullify

  scope :supported, -> { where(provider: SUPPORTED_PROVIDERS) }
  scope :selectable, -> { supported.where(enabled: true) }

  def self.refresh!
    super
    where.not(provider: SUPPORTED_PROVIDERS).delete_all
  end

  def label
    "#{name} (#{provider})"
  end
end
