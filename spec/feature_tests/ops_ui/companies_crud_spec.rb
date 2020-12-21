require 'rails_helper'

RSpec.describe 'Company management', :slow, :browser, type: :feature do

  context 'when a permitted admin is logged in' do

    let(:resource) { create(:company) }
    let(:fill_ins) {{ company_name:              'Company',
                      company_info_phone:        '+49 12 354 738273',
                      company_damage_phone:      '+49 12 354 338273',
                      company_info_email:        'info@insurance.com',
                      company_damage_email:      'damage@insurance.com',
                      company_mandates_email:    'mandates@insurance.com',
                      company_mandates_cc_email: 'mandatescc@insurance.com',
                      company_b2b_contact_info:  'Contact info here',
                      company_national_health_insurance_premium_percentage: '0.9' }}
    let(:selects) {{ company_country_code: translated_country_name('DE') }}
    before :each do
      login_super_admin
    end

    it 'creates a new company', skip: "excluded from nightly, review" do
      visit_new_path(:company)
      i_fill_in_text_fields(fill_ins)
      i_select_options(selects)
      a_resource_is_created(Company)
      i_see_text_fields(fill_ins.merge(
        {
          company_national_health_insurance_premium_percentage: number_to_percentage('0.9')
        }).values + selects.values)
    end

    it 'sees a list of all companies' do
      resource
      visit_index_path(:companies)
      i_see_text_fields([ resource.name,
                          I18n.t('activerecord.state_machines.states.active'),
                          translated_country_name(resource.country_code),
                          I18n.l(resource.created_at, format: :short)])
    end

    it 'updates an existing company', skip: "excluded from nightly, review" do
      visit_edit_path(:company, resource)
      i_fill_in_text_fields(fill_ins)
      i_select_options(selects)
      a_resource_is_updated(Company)
      i_see_text_fields(fill_ins.merge(
        {
          company_national_health_insurance_premium_percentage: number_to_percentage('0.9')
        }).values + selects.values)
    end

    it 'deletes an existing company', skip: "excluded from nightly, review" do
      resource
      visit_index_path(:companies)
      a_resource_is_deleted(Company, delete_path(:company, resource))
    end
  end
end
