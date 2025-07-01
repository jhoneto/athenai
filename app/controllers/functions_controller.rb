class FunctionsController < BaseController
  before_action :set_workspace
  before_action :set_function, only: [ :show, :edit, :update, :destroy, :execute, :run ]

  def index
    @functions = @workspace.functions
  end

  def show
  end

  def new
    @function = @workspace.functions.build
  end

  def create
    @function = @workspace.functions.build(function_params)

    if @function.save
      redirect_to [ @workspace, @function ], notice: "Function was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @function.update(function_params)
      redirect_to [ @workspace, @function ], notice: "Function was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @function.destroy
    redirect_to workspace_functions_url(@workspace), notice: "Function was successfully deleted."
  end

  def execute
    @parameters = @function.parameters || {}
    @execution_result = nil
  end

  def run
    @parameters = @function.parameters || {}
    input_params = params[:function_inputs] || {}

    begin
      @execution_result = execute_function_code(@function, input_params)
    rescue => e
      @execution_result = { error: e.message, backtrace: e.backtrace.first(5) }
    end

    respond_to do |format|
      format.turbo_stream
      format.html { render :execute }
    end
  end

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
    access = workspace_access(@workspace)
    unless access[:owner] || access[:access_functions]
      flash[:alert] = "You don't have permission to access functions in this workspace."
      redirect_to root_path and return
    end
  end

  def set_function
    @function = @workspace.functions.find(params[:id])
  end

  def function_params
    permitted_params = params.require(:function).permit(:name, :code, :description, :tool_type, :return_type, :enabled, parameters: {})

    # Process parameters from the form format to the expected format
    if permitted_params[:parameters].present?
      processed_params = {}
      permitted_params[:parameters].each do |index, param_data|
        next if param_data[:name].blank?

        param_name = param_data[:name]
        processed_params[param_name] = {
          "type" => param_data[:type] || "string",
          "required" => param_data[:required] == "true",
          "description" => param_data[:description] || param_name.humanize
        }
      end
      permitted_params[:parameters] = processed_params
    end

    permitted_params
  end

  def execute_function_code(function, input_params)
    # Criar um contexto isolado para execução
    execution_context = ExecutionContext.new

    # Converter parâmetros de entrada para o formato correto
    processed_params = process_input_parameters(function.parameters, input_params)

    # Executar o código em um ambiente seguro com timeout
    result = Timeout.timeout(30) do
      execution_context.execute_code(function.code, processed_params)
    end

    {
      success: true,
      result: result,
      output: execution_context.captured_output,
      executed_at: Time.current
    }
  rescue Timeout::Error
    { error: "Execution timed out (30 seconds limit)" }
  rescue => e
    { error: e.message, backtrace: e.backtrace.first(5) }
  end

  def process_input_parameters(function_params, input_params)
    return {} if function_params.blank?

    processed = {}
    function_params.each do |param_name, config|
      input_value = input_params[param_name]
      next if input_value.blank? && !config["required"]

      case config["type"]
      when "integer"
        processed[param_name] = input_value.to_i
      when "float"
        processed[param_name] = input_value.to_f
      when "boolean"
        processed[param_name] = [ "true", "1", "yes" ].include?(input_value.to_s.downcase)
      when "array"
        processed[param_name] = input_value.is_a?(Array) ? input_value : input_value.to_s.split(",").map(&:strip)
      else
        processed[param_name] = input_value.to_s
      end
    end
    processed
  end
end
