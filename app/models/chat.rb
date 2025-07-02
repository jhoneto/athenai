class Chat < ApplicationRecord
  acts_as_chat # Assumes Message and ToolCall model names
  belongs_to :agent
  validates :title, presence: true

  scope :ordered, -> { order(updated_at: :desc) }

  def to_llm
    Rails.logger.debug "Using LLM Context for chat with agent: #{agent.name}"
    context = RubyLLM.context do |config|
      config.openai_api_key = agent.llm.api_key
    end

    @chat ||= context.chat(model: model_id)
    @chat.reset_messages!

    messages.each do |msg|
      @chat.add_message(msg.to_llm)
    end

    @chat.on_new_message { persist_new_message }
          .on_end_message { |msg| persist_message_completion(msg) }
  end

  def preview_message
    messages.where(role: 'user').last&.content&.truncate(50) || 'Nova conversa'
  end
end
