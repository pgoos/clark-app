require 'rails_helper'

feature 'User state management', :slow, :browser, :integration do

  let(:resource) { create(:user, mandate: create(:mandate)) }

  before :each do
    login_super_admin
  end

  feature 'The admin activates and deactivates a user' do
    it 'deactivates and activates a user' do
      visit_show_path(:user, resource)

      states_are_changed(User,
                         deactivate: I18n.t('activerecord.state_machines.events.deactivate'),
                         activate: I18n.t('activerecord.state_machines.events.activate'))
    end
  end
end
