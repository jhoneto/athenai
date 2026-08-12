class Llm::Credential < ApplicationRecord
  self.table_name = "llm_credentials"

  belongs_to :account

  enum :provider, { openai: 0, anthropic: 1, gemini: 2, openrouter: 3, vllm: 4, ollama: 5 }

  encrypts :encrypted_api_key

  validates :provider, uniqueness: { scope: :account_id }
  validates :encrypted_api_key, presence: true
end
