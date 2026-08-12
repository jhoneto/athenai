class Llm::Resolver
  def initialize(agent)
    @agent = agent
  end

  def context
    credential = @agent.account.llm_credentials.find_by(provider: @agent.provider)
    return RubyLLM if credential.blank?

    RubyLLM.context do |config|
      config.public_send("#{@agent.provider}_api_key=", credential.encrypted_api_key)
    end
  end
end
