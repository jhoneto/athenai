class SessionsController < ApplicationController
  def index
    @sessions = current_account.sessions.includes(:agent).order(created_at: :desc)
    @available_agents = current_account.agents.available
  end

  def show
    @session = current_account.sessions.find(params[:id])
  end

  def create
    agent = current_account.agents.available.find(params[:agent_id])
    @session = current_account.sessions.create!(agent: agent, user: current_user)
    redirect_to chat_session_path(@session)
  end

  def destroy
    current_account.sessions.find(params[:id]).destroy
    redirect_to chat_sessions_path
  end
end
