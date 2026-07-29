module SubscriptionGuard
  extend ActiveSupport::Concern

  included do
    helper_method :current_subscription
    helper_method :current_plan
  end

  def current_subscription
    @current_subscription ||= current_account&.subscription
  end

  def current_plan
    current_subscription&.plan
  end

  def require_feature!(feature)
    return if current_account&.feature?(feature)
    redirect_to plans_billing_path,
                alert: "Esta funcionalidade requer um plano superior."
  end

  def require_active_subscription!
    return if current_subscription&.can_analyze?
    if current_subscription&.trialing?
      redirect_to plans_billing_path,
                  alert: "Você usou todas as suas análises do trial. Escolha um plano para continuar."
    else
      redirect_to billing_path,
                  alert: "Sua assinatura está #{current_subscription&.status}. Verifique o pagamento."
    end
  end
end
