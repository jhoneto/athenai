class Api::V1::MessagesController < Api::V1::BaseController
  def index
    session = current_account.sessions.find(params[:session_id])
    render json: session.messages
  end

  def create
    session = current_account.sessions.find(params[:session_id])
    session.messages.create!(role: :user, content: message_params[:content])
    AgentResponseJob.perform_later(session.id)

    render json: { status: "queued" }, status: :accepted
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
