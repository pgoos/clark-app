# frozen_string_literal: true

require_relative "../page.rb"

# TODO: refactor related tests and delete this class

class OpsuiPage
  include Page

  def search_mandate(search_term)
    find("#by_id_first_name_cont_last_name_cont_email_cont").send_keys(search_term)
  end

  def search_mandate_by_last_name(search_term)
    find("#by_last_name_cont").send_keys(search_term)
  end

  def click_right_column_search_button
    find(".right-column-content").find_button("Suche").click
  end

  def mandate_result
    expect(page).to have_xpath("//*[starts-with(@id, 'mandate_')]", text: "Automation")
  end

  def assert_inquiry_list(_)
    expect(page).to have_xpath("//*[@id='inquiries']/table/tbody/tr")
  end

  def clicks_inquiry
    find(:xpath, "//*[@id='inquiries']/table/tbody/tr/td[1]/a", match: :first).click
  end

  def assert_page_section(section_heading)
    page.all("div.card-header").each { |section| return nil if section.text.include?(section_heading) }
    raise Capybara::ElementNotFound.new("Section #{section_heading} was not found")
  end

  def attach_file_for_uploading(file=Helpers::OSHelper.upload_file_path("accounting_transactions.xlsx"))
    attach_file("accounting_report_excel_file", file)
  end

  def click_on_section_eye_button(section_heading)
    page.all("div.card-header").each do |section|
      next unless section.text.include?(section_heading)
      section.find(".fa-eye").click
      sleep 1 # animation
      return nil
    end
    raise Capybara::ElementNotFound.new("Eye button was not found in #{section_heading} section")
  end

  def enter_interaction_message(message)
    if TestContextManager.instance.ie_browser?
      find("form.new_interaction_message").find("textarea").set(message)
    else
      find("textarea[class*=editor]").set(message)
    end
  end

  def click_on_section_edit_button(section_heading)
    page.all('.table-responsive tr').each do |section|
      next unless section.text.include?(section_heading)
      section.find("i.glyphicon-pencil").click
      sleep 1 # animation
      return nil
    end
    raise Capybara::ElementNotFound.new("Pencil button was not found in #{section_heading} section")
  end

  def assert_latest_message(message_text)
    expect(first("div#interactions-list .card-body").shy_normalized_text(:all)).to eq(message_text)
  end

  def assert_data_table_present
    table_helper = Helpers::OpsUiHelper::TableHelper.new(node: first(:css, "table", visible: :all))
    expect(table_helper.rows_number).not_to eq(0)
  end

  def assert_empty_input_field
    if TestContextManager.instance.ie_browser?
      expect(("form.new_interaction_message").find("textarea").value).to be_empty
    else
      expect(find("textarea[class*=editor]").value).to be_empty
    end
  end

  def assert_admin_message(message)
    expect(first("div#interactions-list .card-body").shy_normalized_text(:all)).to eq(message)
    expect(first("div#interactions-list .card-header").style("background-color").values).to include("rgba(255, 193, 7, 1)")
  end
end
