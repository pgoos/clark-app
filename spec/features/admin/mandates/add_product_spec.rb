require 'rails_helper'

RSpec.describe 'Adding a product from a mandate', :slow, :browser, :js, type: :feature do
  context 'when a permitted admin is logged in' do
    before :each do
      login_super_admin
    end

    let!(:plan) { create(:plan) }
    let(:company) { plan.company }
    let(:subcompany) { plan.subcompany }
    let(:category) { plan.category }
    let(:mandate) { create(:mandate, user: create(:user)) }

    it 'creates a new product', :js do
      visit new_admin_mandate_product_path(mandate, locale: locale)

      select_from_chosen(:product_category_id, category.name)
      i_select_options(product_company_id: company.name)
      sleep 1
      i_select_options(product_subcompany_id: subcompany.name)

      i_select_options({
        product_premium_period:                I18n.t('attribute_domains.period.month'),
        product_portfolio_commission_period:   I18n.t('attribute_domains.period.year'),
        product_acquisition_commission_period: I18n.t('attribute_domains.period.half_year'),
        product_plan_id:                       plan.name
      })

      i_fill_in_text_fields({
        product_number:                              'ABCD',
        product_contract_started_at:                  2.years.ago,
        product_contract_ended_at:                    1.year.from_now,
        product_notes:                                'Additional info',
        product_premium_price:                        '15,00',
        product_portfolio_commission_price:           '10,00',
        product_acquisition_commission_price:         '40,00',
        product_acquisition_commission_payouts_count: 5,
        product_acquisition_commission_conditions:    'no conditions',
      })

      a_resource_is_created(Product)

      product = Product.last
      expect(product.company).to eq(company)
      expect(product.category).to eq(category)
      expect(product.subcompany).to eq(subcompany)
      expect(product.plan).to eq(plan)

      i_see_the_flash_message_for('create', Product)

      i_see_text_fields([
        'ABCD',
        company.name,
        category.name,
        plan.name,
        I18n.t('activerecord.state_machines.states.details_available')])
    end
  end
end
