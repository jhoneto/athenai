class MessagesController < BaseController
  before_action :set_agent_and_chat

  # POST /agents/:agent_id/chats/:chat_id/messages
  def create
    @message = @chat.messages.build(message_params.merge(role: "user"))

    if @message.save
      # Processar mensagem do usuário e gerar resposta do agente
      ChatService.new(@chat).process_user_message(@message)

      respond_to do |format|
        format.html { redirect_to agent_chat_path(@agent, @chat) }
        format.json { render json: { status: "success" } }
        format.js # Para AJAX
      end
    else
      respond_to do |format|
        format.html {
          redirect_to agent_chat_path(@agent, @chat),
          alert: "Erro ao enviar mensagem"
        }
        format.json { render json: { errors: @message.errors } }
      end
    end
  end

  private

  def set_agent_and_chat
    @agent = Agent.find(params[:agent_id])
    @chat = @agent.chats.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
