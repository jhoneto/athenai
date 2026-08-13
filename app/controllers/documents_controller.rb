class DocumentsController < ApplicationController
  before_action :set_knowledge_base

  def index
    @documents = @knowledge_base.documents.order(created_at: :desc)
  end

  def create
    document = @knowledge_base.documents.create!(filename: params[:file].original_filename)
    document.file.attach(params[:file])
    DocumentIndexJob.perform_later(document.id)
    redirect_to agent_documents_path(@knowledge_base.agent)
  end

  def destroy
    @knowledge_base.documents.find(params[:id]).destroy
    redirect_to agent_documents_path(@knowledge_base.agent)
  end

  private

  def set_knowledge_base
    agent = current_account.agents.find(params[:agent_id])
    @knowledge_base = agent.knowledge_base || agent.create_knowledge_base!
  end
end
