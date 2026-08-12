class Session < ApplicationRecord
  acts_as_chat messages: :messages, message_class: "Message",
               model: :llm_model, model_class: "Llm::Model"

  belongs_to :account
  belongs_to :agent
  belongs_to :llm_profile, class_name: "Llm::Profile"
  belongs_to :user

  enum :status, { open: 0, closed: 1 }

  validates :agent_id, presence: true

  before_validation :copy_llm_profile_and_model, on: :create
  after_create :persist_system_instructions

  def title_or_default
    title.presence || "Conversa #{created_at.to_date}"
  end

  private

  def copy_llm_profile_and_model
    self.llm_profile_id ||= agent&.llm_profile_id
    self.llm_model ||= llm_profile&.llm_model
  end

  def persist_system_instructions
    messages.create!(role: :system, content: agent.system_prompt) if agent.system_prompt.present?
  end
end
