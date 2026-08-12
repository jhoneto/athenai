class Llm::ProfileCatalog
  def initialize(account)
    @account = account
  end

  def selectable_profiles
    Llm::Profile.active.configured.select { |profile| @account.feature?("profile_#{profile.key}") }
  end
end
