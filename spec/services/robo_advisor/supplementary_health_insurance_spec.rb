require 'rails_helper'

describe RoboAdvisor, :integration, :timeout do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Private Krankenzusatzversicherung' do
    let(:category_1) { create(:category, ident: '377e1f7c', name: 'Zahnzusatzversicherung') }
    let(:category_2) { create(:category, ident: 'ce2b05c5', name: 'Krankenhaustagegeldversicherung') }
    let(:category_3) { create(:category, ident: '875823e3', name: 'Reisekrankenversicherung') }
    let(:category_4) { create(:category, ident: '8e92cc77', name: 'Krebs-Schutz Zusatzversicherung') }
    let!(:umbrella_category) { create(:umbrella_category, ident: '2fc69451', included_categories: [category_1, category_2, category_3, category_4]) }

    let!(:product) { create(:product, premium_price: 200.0, premium_period: :year, mandate: mandate, plan: create(:plan, category: category_4)) }

    it_behaves_like 'a robo advice for method', :supplementary_health_insurance

    it 'sends the appropriate text for < 300€ yearly' do
      expect do
        subject.supplementary_health_insurance
      end.to change { product.interactions.count }.by(2)

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.supplementary_health_insurance.ok'), product)
      expect(product.advices.first.content).to eq(expected_text)
    end

    it 'does not send an advice when product costs over 300€ yearly' do
      product.update!(premium_price: 350.0)

      expect do
        subject.supplementary_health_insurance
      end.not_to change(product.interactions, :count)
    end

    it 'advices product when falsely created with umbrella category (LEGACY)', skip: "excluded from nightly, review" do
      product = create(:product, premium_price: 200.0, premium_period: :year, mandate: mandate, plan: create(:plan, category: umbrella_category))

      expect do
        subject.supplementary_health_insurance
      end.to change(product.interactions, :count).by(2)
    end

    it 'does not advice Zahnzusatzversicherung (has own logic)' do
      product = create(:product, premium_price: 200.0, premium_period: :year, mandate: mandate, plan: create(:plan, category: category_1))

      expect do
        subject.supplementary_health_insurance
      end.not_to change(product.interactions, :count)
    end

    it 'does not advice Krankenhaustagegeldversicherung (has own logic)' do
      product = create(:product, premium_price: 200.0, premium_period: :year, mandate: mandate, plan: create(:plan, category: category_2))

      expect do
        subject.supplementary_health_insurance
      end.not_to change(product.interactions, :count)
    end

    it 'does not advice Reisekrankenversicherung (has own logic)' do
      product = create(:product, premium_price: 200.0, premium_period: :year, mandate: mandate, plan: create(:plan, category: category_3))

      expect do
        subject.supplementary_health_insurance
      end.not_to change(product.interactions, :count)
    end
  end
end
