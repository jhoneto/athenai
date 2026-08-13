require "rails_helper"

RSpec.describe "Documents", type: :request do
  let(:account) { create(:account) }
  let(:user)    { create(:user) }
  let(:agent)   { create(:agent, account: account) }

  before do
    create(:account_user, account: account, user: user)
    sign_in user
  end

  describe "GET /agents/:agent_id/documents" do
    it "lists documents belonging to the agent's knowledge base" do
      knowledge_base = create(:knowledge_base, agent: agent)
      document = create(:document, knowledge_base: knowledge_base)

      get agent_documents_path(agent)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(document.filename)
    end

    it "returns not found when the agent belongs to another account" do
      other_agent = create(:agent)

      get agent_documents_path(other_agent)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /agents/:agent_id/documents" do
    it "creates a document, attaches the file, and enqueues indexing" do
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.txt"), "text/plain")
      allow(DocumentIndexJob).to receive(:perform_later)

      expect {
        post agent_documents_path(agent), params: { file: file }
      }.to change { agent.reload.knowledge_base&.documents&.count }.from(nil).to(1)

      expect(DocumentIndexJob).to have_received(:perform_later).with(Document.last.id)
      expect(response).to redirect_to(agent_documents_path(agent))
    end
  end

  describe "DELETE /agents/:agent_id/documents/:id" do
    it "destroys the document" do
      knowledge_base = create(:knowledge_base, agent: agent)
      document = create(:document, knowledge_base: knowledge_base)

      expect {
        delete agent_document_path(agent, document)
      }.to change(Document, :count).by(-1)

      expect(response).to redirect_to(agent_documents_path(agent))
    end

    it "returns not found when the document belongs to another account's agent" do
      other_knowledge_base = create(:knowledge_base)
      other_document = create(:document, knowledge_base: other_knowledge_base)

      delete agent_document_path(other_knowledge_base.agent, other_document)

      expect(response).to have_http_status(:not_found)
    end
  end
end
