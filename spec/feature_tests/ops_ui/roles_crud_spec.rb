require 'rails_helper'

RSpec.describe 'Role management', :slow, :browser, type: :feature do

  context 'when a permitted admin is logged in' do

    let(:resource) { create(:role, name: 'SuperDuperAdmin', identifier: :super_duper_admin) }

    before :each do
      login_super_admin
    end

    it 'creates a new role' do
      visit_new_path(:role)
      i_fill_in_text_fields(role_name: 'SuperDuperAdmin')
      a_resource_is_created(Role)
      i_see_input_values(['SuperDuperAdmin'])
    end

    it 'sees a list of all roles' do
      resource
      visit_index_path(:roles)
      i_see_text_fields([
        resource.name,
        I18n.l(resource.created_at, format: :number) ])
    end

    it 'updates an existing role' do
      resource
      visit_edit_path(:role, resource)
      i_fill_in_text_fields(role_name: 'StackAdmin')
      a_resource_is_updated(Role)
      i_see_input_values(['StackAdmin'])
    end

    it 'deletes an existing role' do
      resource
      visit_index_path(:roles)
      a_resource_is_deleted(Role, delete_path(:role, resource))
    end
  end
end
