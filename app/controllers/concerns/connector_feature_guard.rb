module ConnectorFeatureGuard
  extend ActiveSupport::Concern

  included do
    before_action :require_http_connector_feature!
  end

  private

  def require_http_connector_feature!
    return if current_account.feature?("http_connector")
    redirect_to billing_path, alert: t("connectors.http_connector_required")
  end
end
