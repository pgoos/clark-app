# frozen_string_literal: true

require_relative "../../app/mandate/profiling.rb"
require_relative "../../page.rb"

# TODO: refactor this

class MandateCreationPage
  include Page

  attr_reader :customer, :profiling_page

  def initialize(customer, profiling_page = AppPages::Profiling.new)
    @customer = customer
    @profiling_page = profiling_page
  end

  def select_owner(owner_name)
    page.select owner_name, from: "mandate_owner_ident"
  end

  def enter_customer_data_email(customer)
    fill_email(customer.email)
  end

  def fill_mandate_email_id
    fill_in "mandate_email", with: customer.email
  end

  def fill_mandate_user_email_id
    fill_in "mandate_user_email", with: customer.email
  end

  def fill_password
    fill_in "mandate_user_password", with: customer.password
  end

  def fill_password_confirmation
    fill_in "mandate_user_password_confirmation", with: customer.password
  end

  def upload_mandate_document
    # upload file on the mandate creation page
    attach_file("mandate_document_asset", Helpers::OSHelper.upload_file_path("retirement_cockpit.pdf"))
  end

  def fill_reference_id(reference_id)
    fill_in "mandate_reference_id", with: reference_id
  end

  private

  def fill_email(email)
    fill_in "mandate_email", with: email
  end
end
