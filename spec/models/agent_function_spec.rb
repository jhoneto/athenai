require 'rails_helper'

RSpec.describe AgentFunction, type: :model do
  describe 'validations' do
    let(:workspace) { create(:workspace) }
    let(:llm) { create(:llm, workspace: workspace) }
    let(:agent) { create(:agent, workspace: workspace, llm: llm) }
    let(:function) { create(:function, workspace: workspace) }

    it 'is valid with agent and function' do
      agent_function = build(:agent_function, agent: agent, function: function)
      expect(agent_function).to be_valid
    end

    it 'is invalid without an agent' do
      agent_function = build(:agent_function, agent: nil, function: function)
      expect(agent_function).not_to be_valid
      expect(agent_function.errors[:agent]).to include("must exist")
    end

    it 'is invalid without a function' do
      agent_function = build(:agent_function, agent: agent, function: nil)
      expect(agent_function).not_to be_valid
      expect(agent_function.errors[:function]).to include("must exist")
    end

    it 'enforces uniqueness of agent and function combination' do
      create(:agent_function, agent: agent, function: function)
      duplicate_agent_function = build(:agent_function, agent: agent, function: function)

      expect(duplicate_agent_function).not_to be_valid
      expect(duplicate_agent_function.errors[:agent_id]).to include("has already been taken")
    end

    it 'allows same function with different agents' do
      agent2 = create(:agent, workspace: workspace, llm: llm)

      create(:agent_function, agent: agent, function: function)
      agent_function2 = build(:agent_function, agent: agent2, function: function)

      expect(agent_function2).to be_valid
    end

    it 'allows same agent with different functions' do
      function2 = create(:function, workspace: workspace)

      create(:agent_function, agent: agent, function: function)
      agent_function2 = build(:agent_function, agent: agent, function: function2)

      expect(agent_function2).to be_valid
    end
  end

  describe 'associations' do
    let(:workspace) { create(:workspace) }
    let(:llm) { create(:llm, workspace: workspace) }
    let(:agent) { create(:agent, workspace: workspace, llm: llm) }
    let(:function) { create(:function, workspace: workspace) }
    let(:agent_function) { create(:agent_function, agent: agent, function: function) }

    it 'belongs to agent' do
      expect(agent_function.agent).to eq(agent)
    end

    it 'belongs to function' do
      expect(agent_function.function).to eq(function)
    end
  end

  describe 'model validation constraints' do
    let(:workspace) { create(:workspace) }
    let(:llm) { create(:llm, workspace: workspace) }
    let(:agent) { create(:agent, workspace: workspace, llm: llm) }
    let(:function) { create(:function, workspace: workspace) }

    it 'validates uniqueness at model level' do
      create(:agent_function, agent: agent, function: function)
      duplicate_agent_function = build(:agent_function, agent: agent, function: function)

      expect(duplicate_agent_function).not_to be_valid
      expect(duplicate_agent_function.errors[:agent_id]).to include("has already been taken")
    end
  end
end
