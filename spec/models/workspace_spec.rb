require 'rails_helper'

RSpec.describe Workspace, type: :model do
  describe 'validations' do
    it 'is valid with a name' do
      workspace = build(:workspace)
      expect(workspace).to be_valid
    end

    it 'is invalid without a name' do
      workspace = build(:workspace, name: nil)
      expect(workspace).not_to be_valid
      expect(workspace.errors[:name]).to include("can't be blank")
    end

    it 'is invalid with an empty name' do
      workspace = build(:workspace, name: '')
      expect(workspace).not_to be_valid
      expect(workspace.errors[:name]).to include("can't be blank")
    end
  end

  describe 'associations' do
    let(:workspace) { create(:workspace) }

    it 'has many functions' do
      function1 = create(:function, workspace: workspace)
      function2 = create(:function, workspace: workspace)

      expect(workspace.functions).to include(function1, function2)
    end

    it 'has many llms' do
      llm1 = create(:llm, workspace: workspace)
      llm2 = create(:llm, workspace: workspace)

      expect(workspace.llms).to include(llm1, llm2)
    end

    it 'has many agents' do
      llm = create(:llm, workspace: workspace)
      agent1 = create(:agent, workspace: workspace, llm: llm)
      agent2 = create(:agent, workspace: workspace, llm: llm)

      expect(workspace.agents).to include(agent1, agent2)
    end

    it 'destroys dependent functions when destroyed' do
      function = create(:function, workspace: workspace)

      expect { workspace.destroy }.to change(Function, :count).by(-1)
      expect(Function.find_by(id: function.id)).to be_nil
    end

    it 'destroys dependent llms when destroyed' do
      llm = create(:llm, workspace: workspace)

      expect { workspace.destroy }.to change(Llm, :count).by(-1)
      expect(Llm.find_by(id: llm.id)).to be_nil
    end

    it 'destroys dependent agents when destroyed' do
      llm = create(:llm, workspace: workspace)
      agent = create(:agent, workspace: workspace, llm: llm)

      expect { workspace.destroy }.to change(Agent, :count).by(-1)
      expect(Agent.find_by(id: agent.id)).to be_nil
    end
  end
end
