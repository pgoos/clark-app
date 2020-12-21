# frozen_string_literal: true

# Class provides interfaces for the interaction with Clark API V2 resources
class V2APIAdapter
  # @param client [Client]
  # @param session [Session]
  def initialize(client, session)
    @client = client
    @session = session
  end

  # V2 -----------------------------------------------------------------------------------------------------------------

  def get_csrf_token # rubocop:disable Naming/AccessorMethodName
    resp = @client.execute_http_request("get", "api/authenticity-token", 200)
    @session.csrf_token = resp["token"]
  end

  # ClarkAPI::V2::App::Login -------------------------------------------------------------------------------------------

  # @param email [String]
  # @param password [String]
  def login(email, password)
    @client.execute_http_request("post", "api/app/login", body: {user: {email: email, password: password}})
  end

  # ClarkAPI::V2::App::Register ----------------------------------------------------------------------------------------

  # @param password [String]
  def post_register(password)
    first_name = @session.current_user["lead"]["mandate"]["first_name"]
    last_name = @session.current_user["lead"]["mandate"]["last_name"]
    email = @session.current_user["lead"]["email"]
    @client.execute_http_request("post",
                                 "api/app/register",
                                 201,
                                 body: {mandate: {first_name: first_name, last_name: last_name},
                                        user: {email: email, password: password}})
  end

  # ClarkAPI::V2::Companies --------------------------------------------------------------------------------------------

  # @return [Array] required for the add_inquiries request
  def get_companies # rubocop:disable Naming/AccessorMethodName
    @client.execute_http_request("get", "api/companies", 200)["companies"]
  end

  # ClarkAPI::V2::Concerns::ApiResponsable -----------------------------------------------------------------------------

  def get_current_user # rubocop:disable Naming/AccessorMethodName
    @session.current_user = @client.execute_http_request("get", "api/current_user", 200)
  end

  # @param email [String]
  def update_email(email)
    @session.current_user = @client.execute_http_request("put", "api/current_user", 200, body: {email: email})
  end

  # ClarkAPI::V2::Inquiries --------------------------------------------------------------------------------------------

  # @param inquiries [Array<Array<String>>] - array of arrays [category:company]
  # @param companies [Array] should be obtained via V2APIAdapter.get_companies method
  # @param active_categories [Array] should be obtained via V4APIAdapter.get_active_categories method
  def add_inquiries(inquiries, companies, active_categories)
    # create inquiries list
    inquiries_list = []
    inquiries.each do |inquiry|
      cat_id = str_to_category_id(active_categories, inquiry[0])
      comp_id = str_to_company_id(companies, inquiry[1])
      inquiries_list.append(category_id: cat_id, company_id: comp_id)
    end

    # post inquiries request
    @client.execute_http_request("post", "api/inquiries", 201, body: {inquiries: inquiries_list})
  end

  private

  def str_to_category_id(active_categories, category_name)
    active_categories.each { |category| return category["id"] if category["name"] == category_name }
    raise Exception.new("Category <#{category_name}> was not found")
  end

  def str_to_company_id(companies, company_name)
    companies.each { |company| return company["id"] if company["name"].gsub("&shy;", "") == company_name }
    raise Exception.new("Company <#{company_name}> was not found")
  end

  public

  # ClarkAPI::V2::Mandates ---------------------------------------------------------------------------------------------

  # Method updates customer personal data with provided values
  # @param customer [Model::Customer]
  # @param gender [String]
  # @param iban [String] valid IBAN or empty string
  def update_profile(customer, gender="male", iban="")
    mandate = {first_name: customer.first_name,
               last_name: customer.last_name,
               birthdate: customer.birthdate,
               street: customer.address_line1,
               house_number: customer.house_number.to_s,
               zipcode: customer.zip_code.to_s,
               city: customer.place,
               gender: gender,
               iban: iban}
    @client.execute_http_request("put", "api/mandates/#{@session.current_user_mandate_id}", 200, body: mandate)
  end

  def complete_profiling_step
    complete_wizard_step("profiling")
  end

  def complete_targeting_step
    complete_wizard_step("targeting")
  end

  def complete_confirming_step
    complete_wizard_step("confirming")
  end

  private

  # @param step [String] step name. Valid values: ["confirming", "profiling", "targeting"]
  def complete_wizard_step(step)
    resp = @client.execute_http_request("patch", "api/mandates/#{@session.current_user_mandate_id}/#{step}", 200)
    @session.current_user["lead"]["mandate"] = resp["mandate"]
  end

  public

  # ClarkAPI::V2::Mandates::PhoneVerificationRequest -------------------------------------------------------------------

  # @param phone_number [String]
  def post_phone_number_for_ver(phone_number)
    resource_path = "api/mandates/#{@session.current_user_mandate_id}/primary_phone/phone_verification_request"
    @client.execute_http_request("post",
                                 resource_path,
                                 201,
                                 body: {phone: phone_number.to_s, id: @session.current_user_mandate_id})
  end

  # @param token [String] 4 digit verification token
  def post_phone_number_ver_code(token)
    resource_path = "api/mandates/#{@session.current_user_mandate_id}/primary_phone/phone_verification_request"
    @client.execute_http_request("delete",
                                 resource_path,
                                 204,
                                 body: {token: token.to_s, id: @session.current_user_mandate_id})
  end
end
