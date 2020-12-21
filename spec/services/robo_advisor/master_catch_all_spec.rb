require "rails_helper"

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  subject { RoboAdvisor.new(Logger.new("/dev/null")) }

  let(:device) { create(:device, push_enabled: true) }
  let(:user) { create(:user, devices: [device]) }
  let(:mandate) { create(:mandate, user: user, state: "accepted") }
  let!(:admin) { create(:advice_admin) }

  context "Master Catch All" do
    let(:category) do
      create(:category, ident: 'some category')
    end

    let(:plan) { create(:plan, category: category) }

    let!(:product) do
      create(:product, premium_price:   33.00,
                         premium_period:  :year,
                         mandate:         mandate,
                         plan:            plan)
    end

    let(:category_gkv) do
      create(:category_gkv)
    end

    let(:plan_gkv) { create(:plan_gkv, category: category_gkv) }

    let!(:product_gkv) do
      create(:product, premium_price:   33.00,
                         premium_period:  :year,
                         mandate:         mandate,
                         plan:            plan_gkv)
    end

    it "advices all products in the list" do
      expect do
        subject.master_catch_all
      end.to change { product.interactions.count }

      i18n_key = "robo_advisor.master.catch_all"
      expected_text = subject.advice_template_replacements(I18n.t(i18n_key), product)
      expect(product.advices.first.content).to eq(expected_text)
      expect(product.advices.first.content).not_to match(/translation missing/)
      expect(product.advices.first.content).not_to include(i18n_key)
    end

    it "excludes GKV" do
      expect do
        subject.master_catch_all
      end.not_to change { product_gkv.interactions.count }
    end


    it "excludes products that where made details_available during current run" do
      robo = subject

      Timecop.freeze(Time.zone.now + 15.minutes) do
        product.update!(state: 'takeover_requested')

        expect do
          robo.master_catch_all
        end.not_to change { product.interactions.count }
      end
    end

    it "includes the product who changed state long ago" do
      robo = subject

      Timecop.freeze(1.day.ago) do
        product.update!(state: 'takeover_requested')
      end

      expect do
        robo.master_catch_all
      end.to change { product.interactions.count }
    end
  end
end
