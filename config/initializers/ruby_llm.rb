RubyLLM.configure do |config|
  config.openai_api_key    = Rails.application.credentials.dig(:openai, :api_key)
  config.anthropic_api_key = Rails.application.credentials.dig(:anthropic, :api_key)
  config.gemini_api_key    = Rails.application.credentials.dig(:gemini, :api_key)

  config.use_new_acts_as = true
  config.model_registry_class = "Llm::Model"
end
