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

  def list_tools
    client = RubyLLM::MCP.client(
      name: name,
      transport_type: :streamable,
      config: {
        url: url,
        headers: headers_hash
      }
    )

    puts client

    # tools = client.tools
    # puts "Available tools:"
    # tools.each do |tool|
    #   puts "- #{tool.name}: #{tool.description}"
    # end
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
