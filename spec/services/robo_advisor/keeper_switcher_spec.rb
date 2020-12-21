require "rails_helper"

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  subject { RoboAdvisor.new(Logger.new("/dev/null")) }

  let(:device) { create(:device, push_enabled: true) }
  let(:user) { create(:user, devices: [device]) }
  let(:mandate) { create(:mandate, user: user) }
  let!(:admin) { create(:advice_admin) }

  before do
    #To my knowledge, that should not be necessary, but it is:
    Domain::Classification::QualityForCustomerClassifier.load_classification
  end

  context "Keeper Switcher" do
    let(:category) { create(:category, profit_margin: 1, ident: "keep_switch") }
    let(:plan) { create(:plan, category: category) }
    let(:subcompany) { create(:subcompany, revenue_generating: true) }
    let (:product) do
      create(:product, plan:              plan,
                                   mandate:           mandate,
                                   contract_ended_at: 4.months.from_now,
                                   subcompany:        subcompany)
    end

    before do
      create(:category_phv, enabled_for_advice: true)
    end

    context "keeper/switcher" do
      let!(:advice) do
        advice = create(:advice, topic: product, rule_id: "good")
        advice.update!(created_at: 3.months.ago)

        advice
      end

      it "sends a keeper advice" do
        subject.keeper_switcher

        expect(product.advices.count).to eq(2)

        recent_advice = product.advices.first
        expect(recent_advice.rule_id).to eq("1.1")
      end

      it "sends a switcher advice" do
        advice.rule_id = "bad"
        advice.save

        subject.keeper_switcher

        expect(product.advices.count).to eq(2)

        recent_advice = product.advices.first
        expect(recent_advice.rule_id).to eq("1.0")
      end
    end
  end
end
