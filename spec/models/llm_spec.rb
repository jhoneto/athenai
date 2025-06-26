require 'rails_helper'

RSpec.describe Llm, type: :model do
  describe 'validations' do
    let(:workspace) { create(:workspace) }

    it 'is valid with name, provider, model and workspace' do
      llm = build(:llm, workspace: workspace)
      expect(llm).to be_valid
    end

    it 'is invalid without a name' do
      llm = build(:llm, name: nil, workspace: workspace)
      expect(llm).not_to be_valid
      expect(llm.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without a provider' do
      llm = build(:llm, provider: nil, workspace: workspace)
      expect(llm).not_to be_valid
      expect(llm.errors[:provider]).to include("can't be blank")
    end

    it 'is invalid without a model' do
      llm = build(:llm, model: nil, workspace: workspace)
      expect(llm).not_to be_valid
      expect(llm.errors[:model]).to include("can't be blank")
    end

    it 'is invalid without a workspace' do
      llm = build(:llm, workspace: nil)
      expect(llm).not_to be_valid
      expect(llm.errors[:workspace]).to include("must exist")
    end
  end

  describe 'associations' do
    let(:workspace) { create(:workspace) }
    let(:llm) { create(:llm, workspace: workspace) }

    it 'belongs to workspace' do
      expect(llm.workspace).to eq(workspace)
    end

    it 'has many agents' do
      agent1 = create(:agent, workspace: workspace, llm: llm)
      agent2 = create(:agent, workspace: workspace, llm: llm)

      expect(llm.agents).to include(agent1, agent2)
    end

    it 'destroys dependent agents when destroyed' do
      agent = create(:agent, workspace: workspace, llm: llm)

      expect { llm.destroy }.to change(Agent, :count).by(-1)
      expect(Agent.find_by(id: agent.id)).to be_nil
    end
  end

  describe 'configs serialization' do
    let(:workspace) { create(:workspace) }
    let(:configs) { { temperature: 0.8, max_tokens: 1500, top_p: 0.9 } }

    it 'serializes and deserializes configs as JSON' do
      llm = create(:llm, workspace: workspace, configs: configs)
      llm.reload

      expect(llm.configs).to eq(configs.stringify_keys)
    end

    it 'handles nil configs' do
      llm = create(:llm, workspace: workspace, configs: nil)
      expect(llm.configs).to be_nil
    end

    it 'handles empty configs' do
      llm = create(:llm, workspace: workspace, configs: {})
      llm.reload

      expect(llm.configs).to eq({})
    end
  end
end
