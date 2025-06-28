class SearchWiki < RubyLLM::Tool
  description "Busca em uma wiki propria"

  parameter :query, type: :string, required: true, description: "Pesquisa"

  def execute(query)
    Rails.logger.info("Executing SearchWiki with query: #{query}")
    query.upcase

  rescue => e
    { error: e.message }
  end
end
