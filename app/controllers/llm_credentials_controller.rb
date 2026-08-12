class LlmCredentialsController < ApplicationController
  before_action :require_byok_feature!

  def index
    @llm_credentials = current_account.llm_credentials
  end

  def new
    @llm_credential = current_account.llm_credentials.new
  end

  def create
    @llm_credential = current_account.llm_credentials.new(llm_credential_params)
    @llm_credential.save ? redirect_to(llm_credentials_path) : render(:new, status: :unprocessable_entity)
  end

  def destroy
    current_account.llm_credentials.find(params[:id]).destroy
    redirect_to llm_credentials_path
  end

  private

  def require_byok_feature!
    redirect_to billing_path, alert: t("llm_credentials.byok_required") unless current_account.feature?("byok")
  end

  def llm_credential_params
    params.require(:llm_credential).permit(:provider, :encrypted_api_key)
  end
end
