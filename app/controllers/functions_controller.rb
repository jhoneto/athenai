class FunctionsController < BaseController
  before_action :set_workspace
  before_action :set_function, only: [ :show, :edit, :update, :destroy ]

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

  private

  def set_workspace
    @workspace = Workspace.find(params[:workspace_id])
  end

  def set_function
    @function = @workspace.functions.find(params[:id])
  end

  def function_params
    params.require(:function).permit(:name, :code, :description, :tool_type, parameters: {})
  end
end
