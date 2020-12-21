require 'rails_helper'

RSpec.describe 'Category management', :slow, :browser, type: :feature do
  context 'when a permitted admin is logged in' do
    let!(:resource) { create(:category) }
    let!(:vertical) { create(:vertical) }

    before(:each) do
      login_super_admin
    end

    it 'creates a new category' do
      visit_new_path(:category)
      i_select_options(category_vertical_id: vertical.name)
      i_fill_in_text_fields(category_name: 'Category Name')
      a_resource_is_created(Category)
      i_see_text_fields(['Category Name', I18n.t('activerecord.state_machines.states.active')])
    end

    it 'sees a list of all categories' do
      visit_index_path(:categories)
      i_see_text_fields([resource.name, I18n.t('activerecord.state_machines.states.active'), I18n.l(resource.created_at, format: :number)])
    end

    it 'updates an existing category' do
      visit_edit_path(:category, resource)
      i_fill_in_text_fields(category_name: 'New Category')
      i_select_options(category_vertical_id: vertical.name)
      a_resource_is_updated(Category)
      i_see_text_fields(['New Category', vertical.name])
    end

    it 'deletes a category', skip: "excluded from nightly, review" do
      visit_index_path(:categories)
      a_resource_is_deleted(Category, delete_path(:category, resource))
    end
  end
end
