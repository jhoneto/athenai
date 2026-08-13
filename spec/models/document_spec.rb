require "rails_helper"

RSpec.describe Document, type: :model do
  describe "validations" do
    subject { build(:document) }

    it { is_expected.to belong_to(:knowledge_base) }
    it { is_expected.to have_many(:chunks).class_name("Document::Chunk").dependent(:destroy) }
    it { is_expected.to validate_presence_of(:filename) }
  end

  describe "enum" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, processing: 1, indexed: 2, failed: 3) }
  end

  describe "#account" do
    it "returns the account of the knowledge base's agent" do
      account = create(:account)
      agent = create(:agent, account: account)
      knowledge_base = create(:knowledge_base, agent: agent)
      document = create(:document, knowledge_base: knowledge_base)

      expect(document.account).to eq(account)
    end
  end
end
