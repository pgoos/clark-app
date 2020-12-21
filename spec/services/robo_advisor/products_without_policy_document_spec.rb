require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Diverse Versicherungen (ohne Versicherungsschein)' do
    RoboAdvisor::CATEGORIES_TO_ADVICE_IF_POLICY_IS_MISSING.sample(1).each do |category_ident|
      context "Kategorie: #{category_ident}" do
        if category_ident == 'b8f222d1'
          let!(:category) { create(:category) }
          let!(:umbrella_category) { create(:umbrella_category, ident: 'b8f222d1', included_categories: [category]) }
        else
          let!(:category) { create(:category, ident: category_ident) }
        end

        let!(:company) { create(:company) }
        let!(:product) { create(:product, created_at: 1.year.ago, premium_price: 23.00, premium_period: :year, mandate: mandate, plan: create(:plan, company: company, category: category)) }

        before do
          allow_any_instance_of(Company).to receive(:works_with_us?).and_return(false)
        end

        it_behaves_like 'a robo advice for method', :products_without_policy_document, skip_age_check: true

        it "does not advice product when it is too young" do
          product.update!(created_at: 39.days.ago)

          expect do
            subject.products_without_policy_document
          end.not_to change(product.interactions, :count)
        end

        it "advices the product if it is 41 days old" do
          product.update!(created_at: 41.day.ago)

          expect do
            subject.products_without_policy_document
          end.to change(product.interactions, :count).by(2)
        end

        it 'does not advice a product if it has a policy document' do
          create(:document, documentable: product, document_type: DocumentType.policy)

          expect do
            subject.products_without_policy_document
          end.not_to change(product.interactions, :count)
        end

        it 'does not advice product if company works with us' do
          allow_any_instance_of(Company).to receive(:works_with_us?).and_return(true)

          expect do
            subject.products_without_policy_document
          end.not_to change(product.interactions, :count)
        end

        it 'sends the appropriate text & CTA' do
          subject.products_without_policy_document

          expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.general.no_policy.text'), product)
          advice = product.advices.first
          expect(advice.content).to eq(expected_text)
          expect(advice.cta_link).to eq(I18n.t("robo_advisor.general.no_policy.ctas.#{category_ident}"))
        end
      end
    end
  end
end
