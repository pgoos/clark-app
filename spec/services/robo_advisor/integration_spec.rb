# frozen_string_literal: true

require "rails_helper"

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  include_context "fake robo advice intent based on classification"

  let(:subject) { RoboAdvisor.new(Logger.new("/dev/null")) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context "Wohngebäudeversicherung" do
    let(:company) { create(:company) }
    let(:category) { create(:category, ident: RoboAdvisor::HOUSE_INSURANCE_IDENT, name: "Wohngebäudeversicherung") }
    let!(:product) { create(:product, mandate: mandate, plan: create(:plan, company: company, category: category)) }

    # SCENARIO:
    # 1. Product is created
    # 2. We run robo_advisor - advice is created
    # 3. We run robo_advisor again - no advice is created
    # 4. We update premium_price_cents and wait 2 days
    # 5. We run robo_advisor - advice is created
    # 7. We update product's notes
    # 6. We wait 2 days
    # 7. We run robo_advisor - no advice is created

    it "follows scenario" do
      product.update!(contract_ended_at: 10.months.from_now)
      subject.home_insurance
      subject.home_insurance
      expect(product.reload.advices.count).to eq 1

      update(product, premium_price_cents: 550_000)
      wait_two_days(product)
      product.reload

      expect(product.last_advice.valid).to eq false
      subject.home_insurance
      expect(product.reload.advices.count).to eq 2

      update(product, notes: "some note")
      wait_two_days(product)
      product.reload

      expect(product.last_advice.valid).to eq false
      subject.home_insurance
      expect(product.reload.advices.count).to eq 2
    end

    def wait_two_days(product)
      product.advices.each { |a| a.update!(created_at: a.created_at - 2.days) }
      product.mandate.update!(last_advised_at: (DateTime.parse(product.mandate.last_advised_at).in_time_zone - 2.days))
    end

    def update(product, attributes)
      product.update!(attributes)
      Domain::Mandates::ProductAdviceInvalidated.call(product)
    end
  end
end
