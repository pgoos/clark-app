# frozen_string_literal: true

require "selenium/webdriver/common/error"
require_relative "wrapper"

# Wrapper handles selenium exceptions
class HandleWebdriverErrorsWrapper
  include Wrapper

  RETRIES_LIMIT = 3

  private

  def wrapper
    retries ||= 0
    yield
  rescue Selenium::WebDriver::Error::WebDriverError => e
    retry if (retries += 1) < RETRIES_LIMIT
    raise e
  end
end
