class Users::RegistrationsController < Devise::RegistrationsController
  def create
    ActiveRecord::Base.transaction do
      super do |user|
        if user.persisted?
          account = Account.create!(name: account_name_param)
          account.account_users.create!(user: user, role: :owner)
          account.create_subscription!(
            status: :trialing,
            trial_analyses_total: 5,
            trial_analyses_used: 0
          )
        end
      end
    end
  rescue ActiveRecord::RecordInvalid
    build_resource(sign_up_params)
    resource.errors.add(:base, "Não foi possível criar a conta. Tente novamente.")
    respond_with resource
  end

  private

  def account_name_param
    params.dig(:user, :account_name).to_s.strip
  end

  def sign_up_params
    params.require(:user).permit(:name, :account_name, :email, :password, :password_confirmation)
  end
end
