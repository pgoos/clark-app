require 'rails_helper'

describe RoboAdvisor, :integration do
  include_context "active robo advisor"
  include_context "silenced robo advisor notifications"
  let(:subject) { RoboAdvisor.new(Logger.new('/dev/null')) }
  let(:mandate) { create(:mandate, user: create(:user, devices: [create(:device, push_enabled: true)])) }
  let!(:admin) { create(:advice_admin) }

  context 'Pflegepflichtversicherung' do
    let(:category) { create(:category, ident: '891ab83e', name: 'Pflegepflichtversicherung') }
    let!(:product) { create(:product, premium_price: 0, premium_period: :none, mandate: mandate, plan: create(:plan, category: category)) }

    it_behaves_like 'a robo advice for method', :mandated_nursing_care_insurance

    it 'sends the appropriate text' do
      subject.mandated_nursing_care_insurance

      expected_text = subject.advice_template_replacements(I18n.t('robo_advisor.mandated_nursing_care_insurance.every_contract'), product)
      expect(product.advices.first.content).to eq(expected_text)
    end

    # todo test interaction count change (push + mail = 2)
  end
end
