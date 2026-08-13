class ApiKey < ApplicationRecord
  belongs_to :account

  validates :name, presence: true

  scope :active, -> { where(revoked_at: nil) }

  class << self
    def create_with_token!(account:, name:)
      raw_token = SecureRandom.hex(24)
      prefix = "ath_live_#{raw_token[0, 8]}"

      key = create!(account: account, name: name, prefix: prefix, token_digest: digest(raw_token))
      [ key, "#{prefix}.#{raw_token}" ]
    end

    def authenticate(token)
      prefix, raw_token = token.to_s.split(".", 2)
      return nil if prefix.blank? || raw_token.blank?

      active.find_by(prefix: prefix, token_digest: digest(raw_token))
    end

    private

    def digest(raw_token)
      Digest::SHA256.hexdigest(raw_token)
    end
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
