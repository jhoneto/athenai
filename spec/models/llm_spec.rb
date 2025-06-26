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

    it 'is invalid with an invalid provider' do
      llm = build(:llm, provider: 'InvalidProvider', workspace: workspace)
      expect(llm).not_to be_valid
      expect(llm.errors[:provider]).to include("is not included in the list")
    end

    it 'is valid with a valid provider from PROVIDERS constant' do
      Llm::PROVIDERS.each do |provider|
        llm = build(:llm, provider: provider, workspace: workspace)
        expect(llm).to be_valid
      end
    end

    describe 'config validations' do
      let(:llm) { build(:llm, workspace: workspace) }

      it 'validates temperature range' do
        llm.temperature = -0.1
        expect(llm).not_to be_valid
        expect(llm.errors[:temperature]).to include("must be greater than or equal to 0.0")

        llm.temperature = 2.1
        expect(llm).not_to be_valid
        expect(llm.errors[:temperature]).to include("must be less than or equal to 2.0")

        llm.temperature = 1.0
        expect(llm).to be_valid
      end

      it 'validates max_tokens is positive' do
        llm.max_tokens = 0
        expect(llm).not_to be_valid
        expect(llm.errors[:max_tokens]).to include("must be greater than 0")

        llm.max_tokens = 1000
        expect(llm).to be_valid
      end

      it 'validates top_p range' do
        llm.top_p = -0.1
        expect(llm).not_to be_valid
        expect(llm.errors[:top_p]).to include("must be greater than or equal to 0.0")

        llm.top_p = 1.1
        expect(llm).not_to be_valid
        expect(llm.errors[:top_p]).to include("must be less than or equal to 1.0")

        llm.top_p = 0.9
        expect(llm).to be_valid
      end

      it 'validates penalty ranges' do
        llm.frequency_penalty = -2.1
        expect(llm).not_to be_valid
        expect(llm.errors[:frequency_penalty]).to include("must be greater than or equal to -2.0")

        llm.presence_penalty = 2.1
        expect(llm).not_to be_valid
        expect(llm.errors[:presence_penalty]).to include("must be less than or equal to 2.0")
      end

      it 'allows blank config values' do
        llm.temperature = nil
        llm.max_tokens = nil
        llm.top_p = nil
        expect(llm).to be_valid
      end
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

  describe 'store_accessor attributes' do
    let(:workspace) { create(:workspace) }

    it 'allows setting and getting store_accessor attributes' do
      llm = create(:llm, workspace: workspace,
                   temperature: 0.8,
                   max_tokens: 1500,
                   top_p: 0.9,
                   api_key: 'sk-test123')
      llm.reload

      expect(llm.temperature).to eq(0.8)
      expect(llm.max_tokens).to eq(1500)
      expect(llm.top_p).to eq(0.9)
      expect(llm.api_key).to eq('sk-test123')
    end

    it 'persists store_accessor attributes in configs column' do
      llm = create(:llm, workspace: workspace)
      llm.update(temperature: 1.2, api_url: 'https://api.example.com')

      expect(llm.configs['temperature']).to eq(1.2)
      expect(llm.configs['api_url']).to eq('https://api.example.com')
    end
  end
end
