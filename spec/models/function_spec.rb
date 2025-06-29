require 'rails_helper'

RSpec.describe Function, type: :model do
  describe 'validations' do
    let(:workspace) { create(:workspace) }

    it 'is valid with all required fields' do
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

    it 'is invalid without description' do
      function = build(:function, description: nil, workspace: workspace)
      expect(function).not_to be_valid
      expect(function.errors[:description]).to include("can't be blank")
    end

    it 'is invalid without parameters' do
      function = build(:function, parameters: nil, workspace: workspace)
      expect(function).not_to be_valid
      expect(function.errors[:parameters]).to include("can't be blank")
    end

    it 'is invalid with invalid tool_type' do
      function = build(:function, tool_type: 'invalid', workspace: workspace)
      expect(function).not_to be_valid
      expect(function.errors[:tool_type]).to include("is not included in the list")
    end

    it 'is valid with custom tool_type' do
      function = build(:function, tool_type: 'custom', workspace: workspace)
      expect(function).to be_valid
    end

    it 'is valid with system tool_type' do
      function = build(:function, tool_type: 'system', workspace: workspace)
      expect(function).to be_valid
    end

    it 'is valid with built_in tool_type' do
      function = build(:function, tool_type: 'built_in', workspace: workspace)
      expect(function).to be_valid
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

  describe 'scopes' do
    let(:workspace) { create(:workspace) }
    let!(:enabled_function) { create(:function, workspace: workspace, enabled: true) }
    let!(:disabled_function) { create(:function, workspace: workspace, enabled: false) }

    describe '.enabled' do
      it 'returns only enabled functions' do
        expect(Function.enabled).to include(enabled_function)
        expect(Function.enabled).not_to include(disabled_function)
      end
    end

    describe '.for_agent' do
      it 'returns functions associated with the agent' do
        llm = create(:llm, workspace: workspace)
        agent = create(:agent, workspace: workspace, llm: llm)
        create(:agent_function, agent: agent, function: enabled_function)

        expect(Function.for_agent(agent)).to include(enabled_function)
        expect(Function.for_agent(agent)).not_to include(disabled_function)
      end
    end
  end

  describe 'callbacks' do
    let(:workspace) { create(:workspace) }

    it 'generates tool file after save' do
      expect_any_instance_of(Function).to receive(:generate_tool_file)
      create(:function, workspace: workspace)
    end
  end

  describe '#generate_params_string' do
    let(:workspace) { create(:workspace) }
    let(:function) { build(:function, workspace: workspace) }

    it 'returns empty string when parameters is blank' do
      function.parameters = {}
      expect(function.generate_params_string).to eq("")
    end

    it 'generates parameter string correctly' do
      function.parameters = {
        "name" => { "type" => "string", "required" => true, "description" => "User name" },
        "age" => { "type" => "integer", "required" => false, "description" => "User age" }
      }
      
      result = function.generate_params_string
      expect(result).to include('parameter :name, type: :string, required: true, description: "User name"')
      expect(result).to include('parameter :age, type: :integer, description: "User age"')
    end
  end

  describe '#generate_inputs_string' do
    let(:workspace) { create(:workspace) }
    let(:function) { build(:function, workspace: workspace) }

    it 'returns empty string when parameters is blank' do
      function.parameters = {}
      expect(function.generate_inputs_string).to eq("")
    end

    it 'generates inputs string correctly' do
      function.parameters = { "name" => {}, "age" => {} }
      expect(function.generate_inputs_string).to eq("name, age")
    end
  end
end
