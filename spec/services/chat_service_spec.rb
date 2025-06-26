require 'rails_helper'

RSpec.describe ChatService, type: :service do
  let(:workspace) { create(:workspace) }
  let(:llm) { create(:llm, :openai, workspace: workspace) }
  let(:agent) { create(:agent, workspace: workspace, llm: llm) }

  let(:valid_text_payload) do
    {
      message: {
        type: "text",
        text: {
          body: "Hello, this is a test message"
        }
      }
    }
  end

  let(:openai_response) do
    {
      id: "chatcmpl-123",
      object: "chat.completion",
      created: 1677652288,
      model: "gpt-4-turbo-preview",
      choices: [
        {
          index: 0,
          message: {
            role: "assistant",
            content: "Hello! How can I assist you today?"
          },
          finish_reason: "stop"
        }
      ],
      usage: {
        prompt_tokens: 9,
        completion_tokens: 12,
        total_tokens: 21
      }
    }
  end

  before do
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(
        status: 200,
        body: openai_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '#call' do
    context 'with valid text payload' do
      it 'creates a new chat and processes text message successfully' do
        result = described_class.call(agent: agent, payload: valid_text_payload)

        expect(result).to be_success
        expect(result.data[:chat_id]).to be_present
        expect(result.data[:response]).to be_present
      end

      it 'uses existing chat when chat_id is provided' do
        existing_chat = create(:chat, agent: agent)
        payload_with_chat_id = valid_text_payload.merge(chat_id: existing_chat.id)
        
        result = described_class.call(agent: agent, payload: payload_with_chat_id)

        expect(result).to be_success
        expect(result.data[:chat_id]).to eq(existing_chat.id)
        expect(result.data[:response]).to be_present
      end

      it 'creates new chat when provided chat_id does not exist' do
        non_existent_payload = valid_text_payload.merge(chat_id: 99_999)

        result = described_class.call(agent: agent, payload: non_existent_payload)

        expect(result).to be_success
        expect(result.data[:chat_id]).to be_present
        expect(result.data[:chat_id]).not_to eq(99_999)
      end
    end

    context 'with invalid payload' do
      it 'fails when payload is blank' do
        result = described_class.call(agent: agent, payload: {})

        expect(result).to be_failure
        expect(result.error).to eq("Payload is required")
      end

      it 'fails when message is missing' do
        result = described_class.call(agent: agent, payload: { chat_id: 1 })

        expect(result).to be_failure
        expect(result.error).to eq("Payload message is required")
      end

      it 'fails when text body is missing for text type' do
        invalid_payload = {
          message: {
            type: "text"
          }
        }

        result = described_class.call(agent: agent, payload: invalid_payload)

        expect(result).to be_failure
        expect(result.error).to eq("Text body is required")
      end

      it 'fails when file data is missing for file type' do
        invalid_payload = {
          message: {
            type: "file"
          }
        }

        result = described_class.call(agent: agent, payload: invalid_payload)

        expect(result).to be_failure
        expect(result.error).to eq("File data is required")
      end

      it 'fails when audio data is missing for audio type' do
        invalid_payload = {
          message: {
            type: "audio"
          }
        }

        result = described_class.call(agent: agent, payload: invalid_payload)

        expect(result).to be_failure
        expect(result.error).to eq("Audio data is required")
      end
    end

    context 'with file and audio types (not implemented)' do
      it 'raises NotImplementedError for file type' do
        file_payload = {
          message: { type: "file" },
          file: { name: "test.txt", data: "content" }
        }

        expect {
          described_class.call(agent: agent, payload: file_payload)
        }.to raise_error(NotImplementedError, "File processing not implemented")
      end

      it 'raises NotImplementedError for audio type' do
        audio_payload = {
          message: { type: "audio" },
          audio: { format: "mp3", data: "audio_data" }
        }

        expect {
          described_class.call(agent: agent, payload: audio_payload)
        }.to raise_error(NotImplementedError, "Audio processing not implemented")
      end
    end

    context 'when unexpected errors occur' do
      it 'handles StandardError and returns failure' do
        allow(Chat).to receive(:create!)
          .and_raise(StandardError, "Database connection error")

        result = described_class.call(agent: agent, payload: valid_text_payload)

        expect(result).to be_failure
        expect(result.error).to eq("Database connection error")
      end
    end

    context 'when OpenAI API fails' do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(status: 500, body: "Internal Server Error")
      end

      it 'handles API errors gracefully' do
        result = described_class.call(agent: agent, payload: valid_text_payload)

        expect(result).to be_failure
        expect(result.error).to be_present
      end
    end
  end

  describe 'private methods' do
    subject(:service) { described_class.new(agent: agent, payload: valid_text_payload) }

    describe '#validate_payload!' do
      it 'does not raise error for valid text payload' do
        expect { service.send(:validate_payload!) }.not_to raise_error
      end
    end

    describe '#find_or_create_chat' do
      context 'when no chat_id provided' do
        it 'creates new chat' do
          expect { service.send(:find_or_create_chat) }
            .to change(Chat, :count).by(1)
        end
      end

      context 'when chat_id provided' do
        it 'finds existing chat' do
          existing_chat = create(:chat, agent: agent)
          payload_with_chat_id = valid_text_payload.merge(chat_id: existing_chat.id)
          service_with_chat_id = described_class.new(agent: agent, payload: payload_with_chat_id)

          chat = service_with_chat_id.send(:find_or_create_chat)
          expect(chat).to eq(existing_chat)
        end
      end
    end

    describe '#process_text_message' do
      it 'calls ask method on chat and returns response' do
        mock_chat = instance_spy(Chat)
        mock_messages = instance_spy(ActiveRecord::Relation)
        mock_last_message = instance_spy(Message, content: "Response from LLM")

        allow(mock_chat).to receive(:ask).with("Hello, this is a test message")
        allow(mock_chat).to receive(:messages).and_return(mock_messages)
        allow(mock_messages).to receive(:last).and_return(mock_last_message)

        response = service.send(:process_text_message, mock_chat)
        expect(response).to eq("Response from LLM")
        expect(mock_chat).to have_received(:ask).with("Hello, this is a test message")
      end
    end
  end
end