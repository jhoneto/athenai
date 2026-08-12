class Agent < ApplicationRecord
  belongs_to :account
  belongs_to :llm_profile, class_name: "Llm::Profile", optional: true
  has_many :sessions, dependent: :destroy

  enum :status, { draft: 0, published: 1, archived: 2 }

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :temperature, numericality: { in: 0.0..2.0 }

  scope :available, -> { published }

  delegate :provider, :model_id, to: :llm_model, allow_nil: true

  def llm_model
    llm_profile&.llm_model
  end

  def publishable?
    system_prompt.present? && llm_model.present?
  end

  def publish!
    raise ActiveRecord::RecordInvalid, self unless publishable?
    update!(status: :published)
  end
end
