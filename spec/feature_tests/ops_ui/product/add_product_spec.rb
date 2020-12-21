require 'rails_helper'

RSpec.describe 'Adding a product from an inquiry', :slow, :browser, :js, type: :feature do
  context 'when a permitted admin is logged in' do
    let(:fill_ins) do
      {
        product_number:                              'ABCD',
        product_contract_started_at:                  2.years.ago,
        product_contract_ended_at:                    1.year.from_now,
        product_renewal_period:                       12,
        product_notes:                                'Additional info',
        product_premium_price:                        '55,00',
        product_portfolio_commission_price:           '5,00'
      }
    end

    let(:selects) do
      {
        product_premium_period:                I18n.t('attribute_domains.period.month'),
        product_portfolio_commission_period:   I18n.t('attribute_domains.period.half_year'),
        product_subcompany_id:                 subcompany.name,
        product_plan_id:                       plan.name
      }
    end

    let!(:plan) { create(:plan) }
    let(:company) { plan.company }
    let(:subcompany) { plan.subcompany }
    let(:category) { plan.category }
    let!(:inquiry) { create(:inquiry, mandate: create(:mandate, user: create(:user)), company: company) }

    before :each do
      login_super_admin
    end

    it 'creates a new product', js: true do
      visit new_admin_inquiry_product_path(inquiry, locale: locale)
      select_from_chosen(:product_category_id, category.name)
      i_select_options(selects)
      i_fill_in_text_fields(fill_ins)

      a_resource_is_created(Product)

      i_see_text_fields([
        'ABCD',
        inquiry.mandate.name,
        company.name,
        plan.name,
        I18n.t('activerecord.state_machines.states.details_available')])
    end
  end
end
