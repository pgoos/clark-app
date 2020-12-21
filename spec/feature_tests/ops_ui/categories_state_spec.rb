require 'rails_helper'

feature 'Category state management', :slow, :browser, :integration do

  let(:resource) { create(:category) }

  before :each do
    login_super_admin
  end

  feature 'The admin activates and deactivates a category' do
    it 'deactivates and activates a category' do
      visit_show_path(:category, resource)
      states_are_changed(Category,
                         deactivate: I18n.t('activerecord.state_machines.events.deactivate'),
                         activate: I18n.t('activerecord.state_machines.events.activate'))
    end
  end
end
