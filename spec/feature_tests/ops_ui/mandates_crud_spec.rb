require 'rails_helper'

RSpec.describe 'Mandate management', :slow, :browser, type: :feature do
  context 'when a permitted admin is logged in' do
    let!(:resource) { create(:mandate, user: create(:user)) }

    let(:fill_ins) do
      {
        mandate_first_name:       'Ed',
        mandate_last_name:        'Buck',
        mandate_birthdate:        I18n.l(50.years.ago, format: '%Y-%m-%d'),
        mandate_street:           'Goodrich',
        mandate_house_number:     '3334',
        mandate_zipcode:          '48220',
        mandate_city:             'Ferndale'
      }
    end

    let(:selects) do
      {
        mandate_gender:           I18n.t('attribute_domains.gender.male'),
        mandate_country_code:     translated_country_name('DE')
      }
    end

    before :each do
      login_super_admin
    end

    it 'sees a list of mandates on the index page' do
      visit admin_mandates_path(locale: locale)
      i_see_text_fields([resource.first_name, resource.last_name, I18n.l(resource.birthdate, format: I18n.t('date.formats.long')), resource.user.email])
    end

    it 'updates an existing mandate' do
      visit_edit_path(:mandate, resource)
      i_fill_in_text_fields(fill_ins)
      i_select_options(selects)
      a_resource_is_updated(Mandate)
      i_see_text_fields([
        fill_ins[:mandate_first_name],
        fill_ins[:mandate_last_name],
        I18n.l(50.years.ago, format: :date),
        fill_ins[:mandate_street],
        fill_ins[:mandate_house_number],
        fill_ins[:mandate_zipcode],
        fill_ins[:mandate_city],
        selects[:mandate_gender].capitalize,
        selects[:mandate_country_code]
      ])
    end

    it 'deletes an existing mandate' do
      visit_index_path(:mandates)
      a_resource_is_deleted(Mandate, delete_path(:mandate, resource))
    end
  end
end
