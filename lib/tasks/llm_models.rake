namespace :llm do
  desc "Refresh the LLM model registry from each configured provider"
  task refresh_models: :environment do
    Llm::Model.refresh!
    puts "LLM model registry refreshed: #{Llm::Model.count} models."
  end
end
