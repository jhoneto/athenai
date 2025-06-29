class ChatService < BaseService
  def initialize(agent:, payload: {})
    @agent = agent
    @payload = payload
  end

  def call
    validate_payload!

    chat_record = find_or_create_chat
    chat_record.with_instructions(@agent.prompt) if @agent.prompt.present?

    tools = load_agent_tools
    if tools.present?
      chat_record.with_tools(*tools)
    end

    return failure("Chat not found") unless chat_record

    process_message(chat_record)

    success(
      chat_id: chat_record.id,
      response: @message_data
    )
  rescue StandardError => e
    Rails.logger.error("ChatService error: #{e.backtrace.join("\n")}")
    failure(e.message)
  end

  private

  def validate_payload!
    raise StandardError, "Payload is required" if @payload.blank?
    raise StandardError, "Payload message is required" unless @payload[:message].present?

    case @payload[:message][:type]
    when "text"
      raise StandardError, "Text body is required" unless @payload.dig(:message, :text, :body).present?
    when "file"
      raise StandardError, "File data is required" unless @payload[:file].present?
    when "audio"
      raise StandardError, "Audio data is required" unless @payload[:audio].present?
    end
  end

  def find_or_create_chat
    Chat.find_by(id: @payload[:chat_id]) || create_chat
  end

  def create_chat
    Chat.create!(
      model_id: @agent.llm.model,
      agent: @agent
    )
  end

  def process_message(chat)
    @message_data = case @payload[:message][:type]
    when "text"
      process_text_message(chat)
    when "file"
      process_file_message(chat)
    when "audio"
      process_audio_message(chat)
    end
  end

  def process_text_message(chat)
    chat.ask(@payload[:message][:text][:body])
    chat.messages.last.content
  end

  def process_file_message(chat)
    # TODO: Implement file processing logic
    raise NotImplementedError, "File processing not implemented"
  end

  def process_audio_message(chat)
    # TODO: Implement audio processing logic
    raise NotImplementedError, "Audio processing not implemented"
  end

  def load_agent_tools
    tools = []
    workspace_folder = File.join(Rails.root, "app", "tool", @agent.workspace.name.parameterize)

    return tools unless Dir.exist?(workspace_folder)

    @agent.functions.enabled.each do |function|
      tool_file = File.join(workspace_folder, "#{function.name.underscore}.rb")

      if File.exist?(tool_file)
        begin
          # Load the tool file
          require tool_file

          # Get the class name and instantiate
          class_name = function.name.camelize
          tool_class = Object.const_get(class_name)
          tools << tool_class.new
        rescue => e
          Rails.logger.error("Failed to load tool #{function.name}: #{e.message}")
        end
      end
    end

    tools
  end
end
