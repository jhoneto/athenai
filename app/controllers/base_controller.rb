class BaseController < ApplicationController
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!

  protected

  def user_workspaces
    @user_workspaces ||= current_user&.workspaces&.includes(:user_workspaces) || []
  end

  def shared_workspaces
    @shared_workspaces ||= current_user&.shared_workspaces&.includes(:user_workspaces) || []
  end

  def all_user_workspaces
    @all_user_workspaces ||= (user_workspaces + shared_workspaces).uniq
  end

  def workspace_access(workspace)
    return { owner: true, access_llm: true, access_agents: true, access_functions: true } if workspace.user_id == current_user&.id

    user_workspace = workspace.user_workspaces.find_by(user: current_user)
    return { owner: false, access_llm: false, access_agents: false, access_functions: false } unless user_workspace

    {
      owner: false,
      access_llm: user_workspace.access_llm,
      access_agents: user_workspace.access_agents,
      access_functions: user_workspace.access_functions
    }
  end

  helper_method :user_workspaces, :shared_workspaces, :all_user_workspaces, :workspace_access


end