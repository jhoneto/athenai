class McpServer < ApplicationRecord
  validates :name, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validate :headers_must_be_valid_json

  belongs_to :workspace
  has_many :agent_mcp_servers, dependent: :destroy
  has_many :agents, through: :agent_mcp_servers

  scope :enabled, -> { where(enabled: true) }

  def headers_hash
    headers.is_a?(Hash) ? headers : {}
  end

  def self.test
    Timeout.timeout(5) do
      client = RubyLLM::MCP.client(
        name: "local_mcp",
        transport_type: :sse,
        config: {
          url: "http://localhost:3000/mcp/sse"
        }
      )

      tools = client.tools
      puts "Tools:\n"
      puts tools.map { |tool| "  #{tool.name}: #{tool.description}" }.join("\n")
      puts "\nTotal tools: #{tools.size}"
    end
  rescue Timeout::Error
    puts "❌ Timeout: Cliente travou por mais de 10 segundos"
    puts "Problema: Servidor não está respondendo SSE corretamente"
  rescue => e
    puts "❌ Erro: #{e.message}"
  end

  def list_tools
    Timeout.timeout(10) do
      client = RubyLLM::MCP.client(
        name: name,
        transport_type: :sse,
        config: {
          url: url,
          headers: headers_hash
        }
      )

      tools = client.tools
      puts "Available tools:"
      tools.each do |tool|
        puts "- #{tool.name}: #{tool.description}"
      end
    end
  rescue Timeout::Error
    puts "❌ Timeout: Cliente travou por mais de 10 segundos"
    puts "Problema: Servidor não está respondendo SSE corretamente"
  rescue => e
    puts "❌ Erro: #{e.message}"
  end

  private

  def headers_must_be_valid_json
    return if headers.blank?

    unless headers.is_a?(Hash) || headers.is_a?(String)
      errors.add(:headers, "must be a valid JSON object")
      return
    end

    if headers.is_a?(String)
      begin
        JSON.parse(headers)
      rescue JSON::ParserError
        errors.add(:headers, "must be valid JSON")
      end
    end
  end
end
