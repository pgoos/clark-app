# frozen_string_literal: true

require "rails_helper"

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  include_context "fake robo advice intent based on classification"

  let(:subject) { RoboAdvisor.new(Logger.new("/dev/null")) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context "Hausratversicherung" do
    let(:company) { create(:company, ident: RoboAdvisor::GOOD_INSURANCE_HOME_CONTENTS.sample) }
    let(:category) { create(:category, ident: 'e251294f', name: 'Hausratversicherung') }
    let!(:umbrella_category) { create(:umbrella_category, ident: 'b8f222d1', included_categories: [category]) }
    let!(:product) { create(:product, mandate: mandate, plan: create(:plan, company: company, category: category), contract_started_at: Time.now) }

    it_behaves_like "a robo advice for method", :home_contents_insurance

    context "good company advice" do
      it "does catch all rule in the case does not match any other" do
        company.update!(ident: "something-not-in-the-list")

        expect do
          subject.home_contents_insurance
        end.to change(product.interactions, :count)

        expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.home_contents_insurance.catch_all'), product)
        expect(product.advices.first.content).to eq(expected_text)
      end

      RoboAdvisor::GOOD_INSURANCE_HOME_CONTENTS.each do |company_ident|
        it "sends out good company advice for products from company #{company_ident}" do
          company.update!(ident: company_ident)

          expect do
            subject.home_contents_insurance
          end.to change(product.interactions, :count).by(2)

          expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.home_contents_insurance.good_insurance'), product)
          expect(product.advices.first.content).to eq(expected_text)
        end
      end
    end

    context "started more than 3 years ago" do
      let(:company) { create(:company, ident: "no_good_insurance") }

      it "sends advice your product is old" do
        product.update!(contract_started_at: 4.years.ago, company: company)

        expect do
          subject.home_contents_insurance
        end.to change(product.interactions, :count).by(2)

        expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.home_contents_insurance.old_insurance'), product)
        product.reload

        expect(product.advices.first.content).to eq(expected_text)
        expect(product.advices.first.content).not_to include("#\{vertragsbeginn\}")
      end
    end

    context "ends after 12.months.from.now" do
      let(:company) { create(:company, ident: "no_good_insurance") }

      it "sends advice your product is old" do
        product.update!(contract_ended_at: 13.months.from_now, company: company)

        expect do
          subject.home_contents_insurance
        end.to change(product.interactions, :count).by(2)

        expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.home_contents_insurance.insurance_will_end'), product)
        product.reload

        expect(product.advices.first.content).to eq(expected_text)
      end

      it "sends the catch all advice for no end date" do
        product.update!(contract_ended_at: nil)

        expect do
          subject.home_contents_insurance
        end.to change(product.interactions, :count).by(2)

        expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.home_contents_insurance.catch_all'), product)
        expect(product.advices.first.content).to eq(expected_text)
      end
    end

    context "switch advices" do
      it "sends the switch advice to Asstel products asste505166" do
        company.update!(ident: "asste505166")

        expect do
          subject.home_contents_insurance
        end.to change(product.interactions, :count).by(2)

        content = I18n.t("robo_advisor.home_contents_insurance.switch_asstel")
        expected_text = subject.advice_template_replacements(content, product)

        expect(product.advices.first.content).to eq(expected_text)
        expect(product.advices.first.rule_id).to eq("4.8")
        expect(product.advices.first.identifier).to eq("home_contents_insurance_switch")
      end

      it "sends the switch advice to Huk products huk2466e28b" do
        company.update!(ident: "huk2466e28b")

        expect do
          subject.home_contents_insurance
        end.to change(product.interactions, :count).by(2)

        content = I18n.t("robo_advisor.home_contents_insurance.switch_huk")
        expected_text = subject.advice_template_replacements(content, product)

        expect(product.advices.first.content).to eq(expected_text)
        expect(product.advices.first.rule_id).to eq("4.9")
        expect(product.advices.first.identifier).to eq("home_contents_insurance_switch")
      end

      it "sends the switch advice to Generali products gener339e31" do
        company.update!(ident: "gener339e31")

        expect do
          subject.home_contents_insurance
        end.to change(product.interactions, :count).by(2)

        content = I18n.t("robo_advisor.home_contents_insurance.switch_generali")
        expected_text = subject.advice_template_replacements(content, product)

        expect(product.advices.first.content).to eq(expected_text)
        expect(product.advices.first.rule_id).to eq("4.10")
        expect(product.advices.first.identifier).to eq("home_contents_insurance_switch")
      end
    end
  end
end
