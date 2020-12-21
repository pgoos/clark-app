RSpec.shared_examples "a resource that is listed on the index page" do
  scenario 'with allowed permissions' do
    visit path
    i_see_text_fields(expected_text,
                      find_by_id("#{resource.model_name.singular}_#{resource.id}"))
  end
end

RSpec.shared_examples "a resource that can be created" do |model|
  scenario 'with allowed permissions' do
    visit path

    i_check_boxes(checkboxes)
    i_select_options(selects)
    i_fill_in_text_fields(fill_ins)

    click_button 'create'

    i_see_the_flash_message_for('create', model)

    i_see_text_fields(expected_text,
                      find('.center-column-content'))

    i_see_input_values(expected_input_values,
                       find('.center-column-content'))
  end
end

RSpec.shared_examples "a resource that can be updated" do |model|
  scenario 'with allowed permissions' do
    visit path

    i_select_options(selects)
    i_fill_in_text_fields(fill_ins)

    click_button 'update'

    i_see_the_flash_message_for('update', model)

    i_see_text_fields(expected_text)

    i_see_input_values(expected_input_values)
  end
end

RSpec.shared_examples "a resource that can be deleted" do |model|
  feature 'The admin destroys an admin' do
    scenario 'with allowed permissions' do
      visit index_path

      delete_link = find_link "delete_#{model.model_name.singular}_#{resource.id}"

      expect(delete_link['data-method']).to eq('delete')
      expect(delete_link['href']).to eq(delete_path)
      expect {
        http_delete(delete_path)
      }.to change(model, :count).by(-1)

      i_see_the_flash_message_for('destroy', model)
    end
  end
end

RSpec.shared_examples "a state machine" do |model|
  feature 'The admin changes the admin state' do
    scenario 'with allowed permissions' do
      visit path

      states_are_changed(model, events)
    end
  end
end
