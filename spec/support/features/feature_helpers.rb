module FeatureHelpers
  include ActionView::Helpers::NumberHelper

  def login_super_admin
    login_as(create(:super_admin), scope: :admin)
  end

  def locale
    :de
  end

  def translated_country_name(code)
    ISO3166::Country.new(code).translation(locale.to_s)
  end

  def http_delete path
    current_driver = Capybara.current_driver
    Capybara.current_driver = :rack_test
    page.driver.submit :delete, path, {}
    Capybara.current_driver = current_driver
  end

  def i_see_text_fields(expected_text, context=page)
    expected_text.each do |text|
      expect(context).to have_content(text)
    end
  end

  def i_see_no_text_fields(expected_text, context=page)
    expected_text.each do |text|
      expect(context).to have_no_content(text)
    end
  end

  def i_see_input_values(expected_input_values, context=page)
    expected_input_values.each do |value|
      expect(context).to have_selector("input[value='#{value}']")
    end
  end

  def i_see_checked_boxes(checks)
    checks.each do |label|
      expect(find("label[for='role_#{label}'] input")).to be_checked
    end
  end

  def i_see_unchecked_boxes(checks)
    checks.each do |label|
      expect(find("label[for='role_#{label}'] input")).to_not be_checked
    end
  end

  def i_check_boxes(checkboxes)
    checkboxes.each { |label| check label } if checkboxes
  end

  def i_uncheck_boxes(checks)
    checks.each { |label| uncheck label }
  end

  def i_select_options(selects)
    selects.each { |field, value| select value, from: field, match: :first } if selects
  end

  def i_fill_in_text_fields(fill_ins)
    fill_ins.each { |field, value| fill_in field, with: value } if fill_ins
  end

  def i_see_the_flash_message_for(action, model)
    expect(page).to have_content I18n.t("flash.actions.#{action}.notice", resource_name: model.model_name.human)
  end

  def visit_index_path(scope)
    visit polymorphic_path([:admin, scope], locale: locale)
  end

  def visit_new_path(scope)
    visit new_polymorphic_path([:admin, scope], locale: locale)
  end

  def visit_edit_path(scope, resource)
    visit edit_polymorphic_path([:admin, scope], locale: locale, id: resource.id)
  end

  def visit_show_path(scope, resource)
    visit polymorphic_path([:admin, scope], locale: locale, id: resource.id)
  end

  def delete_path(scope, resource)
    polymorphic_path([:admin, scope], locale: locale, id: resource.id)
  end

  def a_resource_is_created(resource_class)
    expect do
      click_button I18n.t('create')
      i_see_the_flash_message_for('create', resource_class)
    end.to change(resource_class, :count).by(1)
  end

  def a_resource_is_updated(resource_class)
    click_button I18n.t('update')

    i_see_the_flash_message_for('update', resource_class)
  end

  def a_resource_is_deleted(resource_class, delete_path)
    delete_link = find_link "delete_#{resource_class.model_name.singular}_#{resource.id}"

    expect(delete_link['data-method']).to eq('delete')
    expect(delete_link['href']).to eq(delete_path)
    expect do
      http_delete(delete_path)
    end.to change(resource_class, :count).by(-1)

    i_see_the_flash_message_for('destroy', resource_class)
  end

  def states_are_changed(resource_class, events)
    events.each do |event, event_label|
      click_link event_label
      i_see_the_flash_message_for(event, resource_class)
    end
  end

  def select_from_chosen(from, item_text)
    field = find_field(from, visible: false)
    option_value = page.evaluate_script("$(\"##{field[:id]} option:contains('#{item_text}')\").val()")
    page.execute_script("value = ['#{option_value}']\; if ($('##{field[:id]}').val()) {$.merge(value, $('##{field[:id]}').val())}")
    option_value = page.evaluate_script("value")
    page.execute_script("$('##{field[:id]}').val(#{option_value})")
    page.execute_script("$('##{field[:id]}').trigger('chosen:updated')")
    page.execute_script("$('##{field[:id]}').change()")
  end
end
