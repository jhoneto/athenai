require 'rails_helper'

RSpec.describe Function, type: :model do
  describe 'validations' do
    let(:workspace) { create(:workspace) }

    it 'is valid with name, code and workspace' do
      function = build(:function, workspace: workspace)
      expect(function).to be_valid
    end

    it 'is invalid without a name' do
      function = build(:function, name: nil, workspace: workspace)
      expect(function).not_to be_valid
      expect(function.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without code' do
      function = build(:function, code: nil, workspace: workspace)
      expect(function).not_to be_valid
      expect(function.errors[:code]).to include("can't be blank")
    end

    it 'is invalid without a workspace' do
      function = build(:function, workspace: nil)
      expect(function).not_to be_valid
      expect(function.errors[:workspace]).to include("must exist")
    end
  end

  describe 'associations' do
    let(:workspace) { create(:workspace) }
    let(:function) { create(:function, workspace: workspace) }

    it 'belongs to workspace' do
      expect(function.workspace).to eq(workspace)
    end

    it 'has many agent_functions' do
      llm = create(:llm, workspace: workspace)
      agent = create(:agent, workspace: workspace, llm: llm)
      agent_function = create(:agent_function, agent: agent, function: function)

      expect(function.agent_functions).to include(agent_function)
    end

    it 'has many agents through agent_functions' do
      llm = create(:llm, workspace: workspace)
      agent1 = create(:agent, workspace: workspace, llm: llm)
      agent2 = create(:agent, workspace: workspace, llm: llm)

      create(:agent_function, agent: agent1, function: function)
      create(:agent_function, agent: agent2, function: function)

      expect(function.agents).to include(agent1, agent2)
    end

    it 'destroys dependent agent_functions when destroyed' do
      llm = create(:llm, workspace: workspace)
      agent = create(:agent, workspace: workspace, llm: llm)
      agent_function = create(:agent_function, agent: agent, function: function)

      expect { function.destroy }.to change(AgentFunction, :count).by(-1)
      expect(AgentFunction.find_by(id: agent_function.id)).to be_nil
    end
  end
end
