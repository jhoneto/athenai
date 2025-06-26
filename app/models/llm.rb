class Llm < ApplicationRecord
  PROVIDERS = %w[OpenAI Anthropic DeepSeek Llama Gemini].freeze

  validates :name, presence: true
  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :model, presence: true

  belongs_to :workspace
  has_many :agents, dependent: :destroy

  store :configs, accessors: [
    :api_key,
    :api_url,
    :temperature,
    :max_tokens,
    :top_p,
    :top_k,
    :frequency_penalty,
    :presence_penalty,
    :stop_sequences,
    :timeout
  ], coder: JSON

  validates :temperature, numericality: {
    greater_than_or_equal_to: 0.0,
    less_than_or_equal_to: 2.0
  }, allow_blank: true

  validates :max_tokens, numericality: {
    greater_than: 0
  }, allow_blank: true

  validates :top_p, numericality: {
    greater_than_or_equal_to: 0.0,
    less_than_or_equal_to: 1.0
  }, allow_blank: true

  validates :top_k, numericality: {
    greater_than: 0
  }, allow_blank: true

  validates :frequency_penalty, numericality: {
    greater_than_or_equal_to: -2.0,
    less_than_or_equal_to: 2.0
  }, allow_blank: true

  validates :presence_penalty, numericality: {
    greater_than_or_equal_to: -2.0,
    less_than_or_equal_to: 2.0
  }, allow_blank: true

  validates :timeout, numericality: {
    greater_than: 0
  }, allow_blank: true
end
