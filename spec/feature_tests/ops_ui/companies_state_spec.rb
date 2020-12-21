require 'rails_helper'

feature 'Company state management', :slow, :browser, :integration do

  let!(:resource) { create(:company) }

  before :each do
    login_super_admin
  end

  feature 'The admin activates and deactivates a company' do
    it 'deactivates and activates a company' do
      visit_show_path(:company, resource)
      states_are_changed(Company,
                         deactivate: I18n.t('activerecord.state_machines.events.deactivate'),
                         activate: I18n.t('activerecord.state_machines.events.activate'))
    end
  end
end
