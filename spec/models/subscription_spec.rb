require "rails_helper"

RSpec.describe Subscription, type: :model do
  describe "validations" do
    subject { build(:subscription) }

    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:plan).optional }
    it { is_expected.to have_many(:subscription_events).dependent(:destroy) }
    it { is_expected.to validate_uniqueness_of(:account_id) }
  end

  describe "#can_analyze?" do
    context "when trialing" do
      it "returns true when trial quota is not exhausted" do
        sub = build(:subscription, :trialing, trial_analyses_used: 2, trial_analyses_total: 5)
        expect(sub.can_analyze?).to be true
      end

      it "returns false when trial quota is exhausted" do
        sub = build(:subscription, :exhausted_trial)
        expect(sub.can_analyze?).to be false
      end
    end

    context "when active" do
      it "returns true when monthly quota is available" do
        plan = build(:plan, analyses_per_month: 50)
        sub  = build(:subscription, :active, plan: plan, analyses_used: 10)
        expect(sub.can_analyze?).to be true
      end

      it "returns false when monthly quota is exhausted" do
        plan = build(:plan, analyses_per_month: 50)
        sub  = build(:subscription, :active, plan: plan, analyses_used: 50)
        expect(sub.can_analyze?).to be false
      end
    end

    context "when past_due" do
      it "returns false" do
        sub = build(:subscription, :past_due)
        expect(sub.can_analyze?).to be false
      end
    end

    context "when canceled" do
      it "returns false" do
        sub = build(:subscription, :canceled)
        expect(sub.can_analyze?).to be false
      end
    end
  end

  describe "#record_analysis!" do
    it "increments trial_analyses_used when trialing" do
      sub = create(:subscription, :trialing, trial_analyses_used: 1)
      expect { sub.record_analysis! }.to change { sub.reload.trial_analyses_used }.by(1)
    end

    it "does not change analyses_used when trialing" do
      sub = create(:subscription, :trialing)
      expect { sub.record_analysis! }.not_to change { sub.reload.analyses_used }
    end

    it "increments analyses_used when active" do
      sub = create(:subscription, :active, analyses_used: 5)
      expect { sub.record_analysis! }.to change { sub.reload.analyses_used }.by(1)
    end

    it "does not change trial_analyses_used when active" do
      sub = create(:subscription, :active)
      expect { sub.record_analysis! }.not_to change { sub.reload.trial_analyses_used }
    end
  end

  describe "#analyses_remaining" do
    it "returns trial quota remaining when trialing" do
      sub = build(:subscription, :trialing, trial_analyses_total: 5, trial_analyses_used: 3)
      expect(sub.analyses_remaining).to eq(2)
    end

    it "returns infinity when plan is unlimited" do
      plan = build(:plan, :enterprise)
      sub  = build(:subscription, :active, plan: plan)
      expect(sub.analyses_remaining).to eq(Float::INFINITY)
    end

    it "returns monthly quota remaining when active" do
      plan = build(:plan, analyses_per_month: 50)
      sub  = build(:subscription, :active, plan: plan, analyses_used: 30)
      expect(sub.analyses_remaining).to eq(20)
    end
  end

  describe "#quota_percentage" do
    it "returns 0 when trialing" do
      sub = build(:subscription, :trialing)
      expect(sub.quota_percentage).to eq(0)
    end

    it "returns percentage of usage for active subscription" do
      plan = build(:plan, analyses_per_month: 100)
      sub  = build(:subscription, :active, plan: plan, analyses_used: 40)
      expect(sub.quota_percentage).to eq(40)
    end

    it "caps at 100 when over quota" do
      plan = build(:plan, analyses_per_month: 50)
      sub  = build(:subscription, :active, plan: plan, analyses_used: 60)
      expect(sub.quota_percentage).to eq(100)
    end
  end
end
