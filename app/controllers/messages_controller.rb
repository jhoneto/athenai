class MessagesController < ApplicationController
  def create
    @session = current_account.sessions.find(params[:chat_session_id])
    content = message_params[:content]

    if content.present?
      @session.messages.create!(role: :user, content: content)
      AgentResponseJob.perform_later(@session.id)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chat_session_path(@session) }
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
