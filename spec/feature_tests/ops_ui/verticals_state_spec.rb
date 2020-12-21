require 'rails_helper'

feature 'Vertical state management', :browser, :integration do

  let(:resource) { create(:vertical) }

  before :each do
    login_super_admin
  end

  feature 'The admin activates and deactivates a vertical' do
    it 'deactivates and activates a vertical' do
      visit_show_path(:vertical, resource)
      states_are_changed(Vertical,
                         deactivate: I18n.t('activerecord.state_machines.events.deactivate'),
                         activate: I18n.t('activerecord.state_machines.events.activate'))
    end
  end
end
