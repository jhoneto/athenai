# frozen_string_literal: true

class Api::MessagesController < Api::BaseController
  def create
    agent = current_workspace.agents.find_by(uuid: params[:agent])
    response = ChatService.call(agent: agent, payload: params)

    render json: response
  end
end
