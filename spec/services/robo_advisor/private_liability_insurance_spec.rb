# frozen_string_literal: true

require "rails_helper"

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  include_context "fake robo advice intent based on classification"

  subject { RoboAdvisor.new(Logger.new("/dev/null")) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  before do
    allow(mandate).to receive(:pushable_devices?).and_return(true)
  end

  context "Privathaftpflicht (mit Versicherungsschein)" do
    # Make sure that we do not accidentally create a company with one of the ids that have a special advice
    let(:company) { create(:company, ident: "something-not-in-the-list") }
    let(:category) do
      create(:category, ident: "03b12732", name: "Privathaftpflichtversicherung", coverage_features: [
                           CoverageFeature.new(identifier: "dckngc12f5331a9f374fb", name: "Deckungssumme - Sach", definition: "Deckungssumme Sachschäden", value_type: "Money"),
                           CoverageFeature.new(identifier: "dckng7eecd7eff390d702", name: "Deckungssumme - Vermögen", definition: "Deckungssumme Vermögensschäden", value_type: "Money")
                         ])
    end
    let!(:phv_questionnaire) do
      q = create(:questionnaire, category: category, identifier: "ewBzTS")
      category.update_attributes!(questionnaire: q)
      q
    end
    let(:subcompany) { create(:subcompany, pools: ["fonds_finanz"]) }
    let(:black_list_subcompany) { create(:subcompany, pools: []) }
    let(:plan) do
      create(:plan, subcompany: subcompany,
                                company:    company,
                                category:   category)
    end
    let!(:product) { create(:product, premium_price: 120.00, premium_period: :year, mandate: mandate, plan: plan) }
    let!(:document) { create(:document, documentable: product, document_type: DocumentType.policy) }

    it_behaves_like "a robo advice for method", :private_liability_insurance

    it "does not send out an advice when the policy document is missing" do
      document.destroy

      expect do
        subject.private_liability_insurance
      end.not_to change { product.interactions.count }
    end

    it "2.1 - sends the appropriate advice for Deckungssumme (Sach) < 10 Mio" do
      product.update!(coverages: { "dckngc12f5331a9f374fb" => ValueTypes::Money.new(5_000_000, "EUR") })

      subject.private_liability_insurance

      expected_text = subject.advice_template_replacements(I18n.t("robo_advisor.private_liability_insurance.bad_coverage"), product)
      product.reload

      expect(product.advices.first.content).to eq(expected_text)
    end

    it "2.2 - sends the appropriate advice for Deckungssumme (Vermögen) < 10 Mio" do
      product.update!(coverages: { "dckng7eecd7eff390d702" => ValueTypes::Money.new(5_000_000, "EUR") })

      subject.private_liability_insurance

      expected_text = subject.advice_template_replacements(I18n.t("robo_advisor.private_liability_insurance.bad_coverage"), product)
      product.reload

      expect(product.advices.first.content).to eq(expected_text)
    end

    it "sends the appropriate text for price > 90€" do
      subject.private_liability_insurance

      expected_text = subject.advice_template_replacements(I18n.t("robo_advisor.private_liability_insurance.too_expensive"), product)
      expect(product.advices.first.content).to eq(expected_text)
    end

    it "sends the cta link for phv questionnaire" do
      subject.private_liability_insurance
      expect(product.advices.first.cta_link).to eq(RoboAdvisor.phv_questionnaire_link)
    end

    it "sends the cta text to override cta link questionnaire in the advice view" do
      subject.private_liability_insurance
      expect(product.advices.first.cta_text).to eq(I18n.t("manager.products.advice.phv_questionnaire_cta"))
    end

    it "sets disable reply to true to disable the user from taking any other actions than answering the questionnaire" do
      subject.private_liability_insurance
      expect(product.advices.first.disable_reply).to eq(true)
    end

    it "sends the appropriate text for price 1€ < price  < 60€" do
      product.update!(premium_price: 45.0)

      expect do
        subject.private_liability_insurance
      end.to change(product.interactions, :count).by(2)

      advice_text_ident = "robo_advisor.private_liability_insurance.pay_in_full"
      expected_text = subject.advice_template_replacements(I18n.t(advice_text_ident), product)
      product.reload

      expect(product.advices.first.content).not_to include(advice_text_ident)
      expect(product.advices.first.content).to eq(expected_text)
    end

    context "2.10 - catch all advice" do
      let!(:product) { create(:product,
                                          premium_price:  110.00,
                                          premium_period: :year,
                                          mandate:        mandate,
                                          plan:           plan) }

      it "advice catch all for product if price < 90€ && > 60€" do
        product.update!(premium_price: 70.0)

        expect do
          subject.private_liability_insurance
        end.to change(product.interactions, :count).by(2)
      end

      it "advice catch all when Deckungssummen are over 10 Mio and product is cheap enough" do
        product.update!(premium_price: 75.0,
                                  coverages: {
                                    "dckng7eecd7eff390d702" => ValueTypes::Money.new(15_000_000, "EUR"),
                                    "dckngc12f5331a9f374fb" => ValueTypes::Money.new(15_000_000, "EUR")
                                  })

        expect do
          subject.private_liability_insurance
        end.to change(product.interactions, :count).by(2)

        advice_text_ident = "robo_advisor.private_liability_insurance.catch_all"
        expected_text = subject.advice_template_replacements(I18n.t(advice_text_ident), product)
        product.reload

        expect(product.advices.first.content).not_to include(advice_text_ident)
        expect(product.advices.first.content).to eq(expected_text)
      end
    end

    context "2.6 - good company (with payment) advice" do
      before { product.update!(premium_price: 61.0) }

      RoboAdvisor::GOOD_INSURANCE_PRIVATE_LIABILITY_WITH_PAYMENT.each do |company_ident|
        it "sends out good company advice for products from company #{company_ident}" do
          company.update!(ident: company_ident)

          expect do
            subject.private_liability_insurance
          end.to change(product.interactions, :count).by(2)

          advice_text_ident = "robo_advisor.private_liability_insurance.good_insurance_with_payment"
          expected_text = subject.advice_template_replacements(I18n.t(advice_text_ident), product)
          product.reload

          expect(product.advices.first.content).not_to include(advice_text_ident)
          expect(product.advices.first.content).to eq(expected_text)
        end
      end
    end

    context "2.6.b - good company advice" do
      before { product.update!(premium_price: 50.0) }

      RoboAdvisor::GOOD_INSURANCE_PRIVATE_LIABILITY.each do |company_ident|
        it "sends out good company advice for products from company #{company_ident}" do
          company.update!(ident: company_ident)

          expect do
            subject.private_liability_insurance
          end.to change(product.interactions, :count).by(2)

          advice_text_ident = "robo_advisor.private_liability_insurance.good_insurance"
          expected_text = subject.advice_template_replacements(I18n.t(advice_text_ident), product)
          product.reload

          expect(product.advices.first.content).not_to include(advice_text_ident)
          expect(product.advices.first.content).to eq(expected_text)
        end
      end
    end

    context "2.11 - rule for products in umdeckung" do
      before { product.update!(premium_price: 61.0) }

      it "2.4 - send umdeckung for product not im pool" do
        plan.update!(subcompany: black_list_subcompany)
        company.update!(ident: "fonds_finanz")

        expect do
          subject.private_liability_insurance
        end.to change(product.interactions, :count).by(2)

        advice_text_ident = "robo_advisor.private_liability_insurance.umdeckung"
        expected_text = subject.advice_template_replacements(I18n.t(advice_text_ident), product)
        product.reload

        expect(product.advices.first.content).not_to include(advice_text_ident)
        expect(product.advices.first.content).to eq(expected_text)
      end
    end

    context "specific to companies" do
      it "2.13 - switch rule for cosmos" do
        product.company.update!(ident: RoboAdvisor::PHV_COSMOS)

        subject.private_liability_insurance

        content = I18n.t("robo_advisor.private_liability_insurance.switch_cosmos")
        expected_text = subject.advice_template_replacements(content, product)
        expect(product.advices.first.content).to eq(expected_text)
      end

      it "2.14 - switch rule for debeka" do
        product.company.update!(ident: RoboAdvisor::PHV_DEBEKA)

        subject.private_liability_insurance

        content = I18n.t("robo_advisor.private_liability_insurance.switch_debeka")
        expected_text = subject.advice_template_replacements(content, product)
        expect(product.advices.first.content).to eq(expected_text)
      end

      it "2.15 - switch rule for asstel" do
        product.company.update!(ident: RoboAdvisor::PHV_ASSTEL)

        subject.private_liability_insurance

        content = I18n.t("robo_advisor.private_liability_insurance.switch_asstel")
        expected_text = subject.advice_template_replacements(content, product)
        expect(product.advices.first.content).to eq(expected_text)
      end

      it "2.16 - switch rule for wgv" do
        product.company.update!(ident: RoboAdvisor::PHV_WGV)

        subject.private_liability_insurance

        content = I18n.t("robo_advisor.private_liability_insurance.switch_wgv")
        expected_text = subject.advice_template_replacements(content, product)
        expect(product.advices.first.content).to eq(expected_text)
      end

      it "2.17 - switch rule for provinzial" do
        product.company.update!(ident: RoboAdvisor::PHV_PROV)

        subject.private_liability_insurance

        content = I18n.t("robo_advisor.private_liability_insurance.switch_provinzial")
        expected_text = subject.advice_template_replacements(content, product)
        expect(product.advices.first.content).to eq(expected_text)
      end

      it "2.18 - switch rule for huk" do
        product.company.update!(ident: RoboAdvisor::PHV_HUK.sample)

        subject.private_liability_insurance

        content = I18n.t("robo_advisor.private_liability_insurance.switch_huk")
        expected_text = subject.advice_template_replacements(content, product)
        expect(product.advices.first.content).to eq(expected_text)
      end

      it "2.19 - switch rule for vgh" do
        product.company.update!(ident: RoboAdvisor::PHV_VGH)

        subject.private_liability_insurance

        content = I18n.t("robo_advisor.private_liability_insurance.switch_vgh_brandkasse")
        expected_text = subject.advice_template_replacements(content, product)
        expect(product.advices.first.content).to eq(expected_text)
      end
    end
  end
end
