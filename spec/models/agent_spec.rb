require 'rails_helper'

RSpec.describe Agent, type: :model do
  describe 'validations' do
    let(:workspace) { create(:workspace) }
    let(:llm) { create(:llm, workspace: workspace) }

    it 'is valid with name, prompt, workspace and llm' do
      agent = build(:agent, workspace: workspace, llm: llm)
      expect(agent).to be_valid
    end

    it 'is invalid without a name' do
      agent = build(:agent, name: nil, workspace: workspace, llm: llm)
      expect(agent).not_to be_valid
      expect(agent.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without a prompt' do
      agent = build(:agent, prompt: nil, workspace: workspace, llm: llm)
      expect(agent).not_to be_valid
      expect(agent.errors[:prompt]).to include("can't be blank")
    end

    it 'is invalid without a workspace' do
      agent = build(:agent, workspace: nil, llm: llm)
      expect(agent).not_to be_valid
      expect(agent.errors[:workspace]).to include("must exist")
    end

    it 'is invalid without an llm' do
      agent = build(:agent, workspace: workspace, llm: nil)
      expect(agent).not_to be_valid
      expect(agent.errors[:llm]).to include("must exist")
    end
  end

  describe 'associations' do
    let(:workspace) { create(:workspace) }
    let(:llm) { create(:llm, workspace: workspace) }
    let(:agent) { create(:agent, workspace: workspace, llm: llm) }

    it 'belongs to workspace' do
      expect(agent.workspace).to eq(workspace)
    end

    it 'belongs to llm' do
      expect(agent.llm).to eq(llm)
    end

    it 'has many agent_functions' do
      function = create(:function, workspace: workspace)
      agent_function = create(:agent_function, agent: agent, function: function)

      expect(agent.agent_functions).to include(agent_function)
    end

    it 'has many functions through agent_functions' do
      function1 = create(:function, workspace: workspace)
      function2 = create(:function, workspace: workspace)

      create(:agent_function, agent: agent, function: function1)
      create(:agent_function, agent: agent, function: function2)

      expect(agent.functions).to include(function1, function2)
    end

    it 'destroys dependent agent_functions when destroyed' do
      function = create(:function, workspace: workspace)
      agent_function = create(:agent_function, agent: agent, function: function)

      expect { agent.destroy }.to change(AgentFunction, :count).by(-1)
      expect(AgentFunction.find_by(id: agent_function.id)).to be_nil
    end
  end

  describe 'workspace and llm consistency' do
    it 'allows agent with llm from the same workspace' do
      workspace = create(:workspace)
      llm = create(:llm, workspace: workspace)
      agent = build(:agent, workspace: workspace, llm: llm)

      expect(agent).to be_valid
    end

    it 'allows agent with llm from different workspace' do
      workspace1 = create(:workspace)
      workspace2 = create(:workspace)
      llm = create(:llm, workspace: workspace2)
      agent = build(:agent, workspace: workspace1, llm: llm)

      expect(agent).to be_valid
    end
  end
end
