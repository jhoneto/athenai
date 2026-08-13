class Api::V1::SessionsController < Api::V1::BaseController
  def create
    agent = current_account.agents.available.find(params[:agent_id])
    session = current_account.sessions.create!(agent: agent, user: system_user)
    render json: session, status: :created
  end

  private

  # MVP: sessão via API roda em nome do primeiro usuário do account; revisar quando houver
  # conceito de "usuário final" desacoplado de User (Fase 2).
  def system_user
    current_account.users.first
  end
end
