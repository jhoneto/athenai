class ChatsController < BaseController
  before_action :set_workspace
  before_action :set_agent
  before_action :set_chat, only: [ :show, :create_message ]

  def index
    @chats = @agent.chats.includes(:messages).order(updated_at: :desc)
    @current_chat = @chats.first
  end

  def show
    @chats = @agent.chats.includes(:messages).order(updated_at: :desc)
    @current_chat = @chat
    @messages = @chat.messages.order(created_at: :asc)
  end

  def create
    @chat = @agent.chats.create!(
      model_id: @agent.llm.model
    )

    redirect_to workspace_agent_chat_path(@workspace, @agent, @chat)
  end

  def create_message
    message_params = params.require(:message).permit(:content)

    payload = {
      chat_id: @chat.id,
      message: {
        type: "text",
        text: {
          body: message_params[:content]
        }
      }
    }

    result = ChatService.new(agent: @agent, payload: payload).call

    respond_to do |format|
      if result.success?
        @messages = @chat.reload.messages.order(created_at: :asc)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("messages", partial: "messages", locals: { messages: @messages }),
            turbo_stream.replace("message-form", partial: "message_form", locals: { workspace: @workspace, agent: @agent, chat: @chat })
          ]
        end
        format.json { render json: { success: true } }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash-messages",
            partial: "shared/flash", locals: { message: result.error, type: "alert" })
        end
        format.json { render json: { success: false, error: result.error } }
      end
    end
  end

  private

  def set_workspace
    @workspace = current_user.workspaces.find(params[:workspace_id])
  end

  def set_agent
    @agent = @workspace.agents.find(params[:agent_id])
  end

  def set_chat
    @chat = @agent.chats.find(params[:id])
  end
end
