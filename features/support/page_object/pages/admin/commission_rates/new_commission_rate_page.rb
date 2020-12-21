# frozen_string_literal: true

require_relative "../../page.rb"

class NewCommissionRate
  include Page

  def select_sales_channel(channel)
    page.select channel, from: "commission_rate_new_contract_sales_channel"
  end

  def assert_default_commission_rate(value, pool)
    pool = pool.parameterize.underscore
    expect(page).to have_selector("input[value='#{value}']", visible: false, id: "default-#{pool}-reserve-sales")
  end
end
