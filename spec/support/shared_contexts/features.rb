# frozen_string_literal: true

RSpec.shared_context "Features Helpers" do
  let(:keep_cookie_banner) { false }
  let(:disable_cookie_banner) do
    next if keep_cookie_banner

    Capybara.current_session.visit("/404")

    driver = Capybara.current_session.driver
    case driver
    when Capybara::Selenium::Driver
      browser = driver.browser
      browser.manage.add_cookie(name: PrivacySetting::BANNER_VISIBILITY_COOKIE, value: "true")
      browser.manage.add_cookie(name: PrivacySetting::MARKETING_TRACKING_COOKIE, value: "true")
      browser.manage.add_cookie(name: PrivacySetting::MARKETING_TRACKING_COOKIE_TIMESTAMP, value: Time.current.to_s)
    else
      if driver.browser.respond_to?(:set_cookie)
        cookie_string = "#{PrivacySetting::BANNER_VISIBILITY_COOKIE}=true; " \
        "#{PrivacySetting::MARKETING_TRACKING_COOKIE}=true; " \
        "#{PrivacySetting::MARKETING_TRACKING_COOKIE_TIMESTAMP}=#{Time.current}"

        driver.browser.set_cookie(cookie_string)
      else
        driver.cookies.add(PrivacySetting::BANNER_VISIBILITY_COOKIE, "true")
        driver.cookies.add(PrivacySetting::MARKETING_TRACKING_COOKIE, "true")
        driver.cookies.add(PrivacySetting::MARKETING_TRACKING_COOKIE_TIMESTAMP, Time.current.to_s)
      end
    end
  end
end
