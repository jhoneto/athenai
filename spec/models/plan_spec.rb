require "rails_helper"

RSpec.describe Plan, type: :model do
  describe "validations" do
    subject { build(:plan) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug) }
    it { is_expected.to validate_numericality_of(:price_cents).is_greater_than_or_equal_to(0) }
  end

  describe "#unlimited?" do
    it "returns true when analyses_per_month is nil" do
      plan = build(:plan, :enterprise)
      expect(plan.unlimited?).to be true
    end

    it "returns false when analyses_per_month is set" do
      plan = build(:plan, :starter)
      expect(plan.unlimited?).to be false
    end
  end

  describe "#feature?" do
    it "returns true for a feature included in the plan" do
      plan = build(:plan, :growth)
      expect(plan.feature?(:convenio_rules)).to be true
    end

    it "returns false for a feature not included in the plan" do
      plan = build(:plan, :starter)
      expect(plan.feature?(:api_access)).to be false
    end
  end

  describe "#price_display" do
    it "returns 'Sob consulta' for zero price" do
      plan = build(:plan, :enterprise)
      expect(plan.price_display).to eq("Sob consulta")
    end

    it "formats price in BRL" do
      plan = build(:plan, :starter)
      expect(plan.price_display).to eq("R$ 297/mês")
    end
  end

  describe ".active scope" do
    it "returns only active plans ordered by price" do
      inactive = create(:plan, active: false, price_cents: 1000)
      starter  = create(:plan, :starter)
      growth   = create(:plan, :growth)

      expect(Plan.active).to eq([ starter, growth ])
      expect(Plan.active).not_to include(inactive)
    end
  end
end
