# frozen_string_literal: true

And(/^"([^"]*)" receives an email with the content "([^"]*)"$/) do |receiver, email_text|
  recipient_email = case receiver
                    when "user"
                      @customer.email
                    when "user's friend"
                      @customer.invitee_email
                    else
                      receiver
                    end
  expect(Helpers::EmailsHelper.retrieve_email_with_content(recipient_email, email_text).nil?).to be(false)
end

Then(/^"([^"]*)" receives an email with the subject "([^"]*)"$/) do |receiver, subject|
  recipient_email = case receiver
                    when "user"
                      @customer.email
                    when "user's friend"
                      @customer.invitee_email
                    else
                      receiver
                    end
  expect(Helpers::EmailsHelper.retrieve_email_with_subject(recipient_email, subject).nil?).to be(false)
end

When(/^user clicks "([^"]*)" link from email$/) do |url_sub_string|
  url = Helpers::EmailsHelper.fetch_url_from_email(@customer.email, url_sub_string)
  expect(url).not_to be_nil
  Helpers::NavigationHelper.navigate_to_url(url)
end
