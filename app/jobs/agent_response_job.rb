class AgentResponseJob < ApplicationJob
  queue_as :default

  def perform(session_id)
    session = Session.find(session_id)
    session.context = Llm::Resolver.new(session.agent).context
    session.complete
  end
end
