class ChatsController < BaseController
  before_action :set_agent, only: [:show, :create, :destroy]
  before_action :set_chat, only: [:show, :destroy]

  # GET /agents/:agent_id/chats/:id
  def show
    @chats = @agent.chats.ordered
    @messages = @chat.messages.includes(:tool_call).order(:created_at)
  end

  # POST /agents/:agent_id/chats
  def create
    @chat = @agent.chats.build(chat_params)
    @chat.title = chat_params[:title].presence || "Chat #{@agent.chats.count + 1}"
    
    if @chat.save
      redirect_to agent_chat_path(@agent, @chat)
    else
      redirect_to agent_path(@agent), alert: 'Erro ao criar chat'
    end
  end

  # DELETE /agents/:agent_id/chats/:id
  def destroy
    @chat.destroy
    redirect_to agent_path(@agent), notice: 'Chat excluído com sucesso'
  end

  private

  def set_agent
    @agent = current_workspace.agents.find(params[:agent_id])
  end

  def set_chat
    @chat = @agent.chats.find(params[:id])
  end

  def chat_params
    params.require(:chat).permit(:title)
  end
end