require "rails_helper"

RSpec.describe Document::Chunk, type: :model do
  describe "validations" do
    subject { build(:document_chunk) }

    it { is_expected.to belong_to(:document) }
    it { is_expected.to validate_presence_of(:content) }
  end
end
