require 'rails_helper'

RSpec.describe FunctionsController, type: :controller do
  let(:user) { create(:user) }
  let(:workspace) { create(:workspace, user: user) }
  let(:function) { create(:function, workspace: workspace) }

  before do
    sign_in user
  end

  describe "GET #execute" do
    it "returns a success response" do
      get :execute, params: { workspace_id: workspace.id, id: function.id }
      expect(response).to be_successful
    end

    it "assigns @function" do
      get :execute, params: { workspace_id: workspace.id, id: function.id }
      expect(assigns(:function)).to eq(function)
    end

    it "assigns @workspace" do
      get :execute, params: { workspace_id: workspace.id, id: function.id }
      expect(assigns(:workspace)).to eq(workspace)
    end

    it "assigns @parameters" do
      get :execute, params: { workspace_id: workspace.id, id: function.id }
      expect(assigns(:parameters)).to eq(function.parameters)
    end

    it "initializes @execution_result as nil" do
      get :execute, params: { workspace_id: workspace.id, id: function.id }
      expect(assigns(:execution_result)).to be_nil
    end
  end

  describe "POST #run" do
    let(:function_inputs) { { "input" => "test value" } }

    context "with successful execution" do
      before do
        controller_instance = instance_double(described_class)
        allow(controller).to receive(:execute_function_code)
          .and_return({ success: true, result: "output", output: StringIO.new("console output"), executed_at: Time.current })
      end

      it "returns a success response" do
        post :run, params: { workspace_id: workspace.id, id: function.id, function_inputs: function_inputs }
        expect(response).to be_successful
      end

      it "assigns execution result" do
        post :run, params: { workspace_id: workspace.id, id: function.id, function_inputs: function_inputs }
        expect(assigns(:execution_result)).to include(:success, :result, :output, :executed_at)
      end

      it "renders execute template" do
        post :run, params: { workspace_id: workspace.id, id: function.id, function_inputs: function_inputs }
        expect(response).to render_template(:execute)
      end
    end

    context "with execution error" do
      before do
        allow(controller).to receive(:execute_function_code)
          .and_return({ error: "Runtime error", backtrace: [ "line 1", "line 2" ] })
      end

      it "assigns error result" do
        post :run, params: { workspace_id: workspace.id, id: function.id, function_inputs: function_inputs }
        expect(assigns(:execution_result)).to include(:error, :backtrace)
      end

      it "renders execute template" do
        post :run, params: { workspace_id: workspace.id, id: function.id, function_inputs: function_inputs }
        expect(response).to render_template(:execute)
      end
    end

    context "with exception during execution" do
      before do
        allow(controller).to receive(:execute_function_code)
          .and_raise(StandardError.new("Unexpected error"))
      end

      it "handles exception gracefully" do
        post :run, params: { workspace_id: workspace.id, id: function.id, function_inputs: function_inputs }
        expect(assigns(:execution_result)).to include(:error)
        expect(assigns(:execution_result)[:error]).to eq("Unexpected error")
      end
    end
  end

  describe "#process_input_parameters" do
    let(:controller_instance) { described_class.new }

    context "with different parameter types" do
      it "processes different parameter types correctly" do
        function_params = {
          "string_param" => { "type" => "string", "required" => true },
          "integer_param" => { "type" => "integer", "required" => false },
          "float_param" => { "type" => "float", "required" => false },
          "boolean_param" => { "type" => "boolean", "required" => false },
          "array_param" => { "type" => "array", "required" => false }
        }

        input_params = {
          "string_param" => "test string",
          "integer_param" => "42",
          "float_param" => "3.14",
          "boolean_param" => "true",
          "array_param" => "a,b,c"
        }

        result = controller_instance.send(:process_input_parameters, function_params, input_params)

        expect(result["string_param"]).to eq("test string")
        expect(result["integer_param"]).to eq(42)
        expect(result["float_param"]).to eq(3.14)
        expect(result["boolean_param"]).to be(true)
        expect(result["array_param"]).to eq([ "a", "b", "c" ])
      end
    end

    it "skips blank optional parameters" do
      function_params = {
        "optional_param" => { "type" => "string", "required" => false }
      }
      input_params = { "optional_param" => "" }

      result = controller_instance.send(:process_input_parameters, function_params, input_params)
      expect(result).not_to have_key("optional_param")
    end
  end

  context "when user does not have access to workspace" do
    let(:other_workspace) { create(:workspace) }
    let(:other_function) { create(:function, workspace: other_workspace) }

    it "redirects to root path for execute" do
      get :execute, params: { workspace_id: other_workspace.id, id: other_function.id }
      expect(response).to redirect_to(root_path)
    end

    it "redirects to root path for run" do
      post :run, params: { workspace_id: other_workspace.id, id: other_function.id }
      expect(response).to redirect_to(root_path)
    end
  end
end
