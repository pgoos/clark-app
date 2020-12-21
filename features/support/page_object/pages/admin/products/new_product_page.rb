# frozen_string_literal: true

require "securerandom"
require_relative "../../page.rb"

class NewProductPage
  include Page

  def select_product_category(category)
    Helpers::OpsUiHelper.select_select2_option("product_category_id", category)
  end

  def select_product_group(group)
    page.select group, from: "product_company_id"
  end

  def select_product_sub_company(sub_company)
    page.select sub_company, from: "product_subcompany_id"
  end

  def select_product_tarif(plan)
    page.select plan, from: "product_plan_id"
  end

  def enter_random_product_number
    new_product_number = SecureRandom.uuid
    fill_in "product_number", with: new_product_number
    new_product_number
  end

  def select_product_premium_period(period)
    page.select period, from: "product_premium_period"
  end
end
