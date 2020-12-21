# frozen_string_literal: true

require_relative "../service/fake_smtp_service/fake_smtp_service_factory.rb"
require "uri"
require "date"
require "time"

module Helpers
  module EmailsHelper
    module_function

    EMAIL_FETCHING_TIMEOUT = 120
    private_constant :EMAIL_FETCHING_TIMEOUT

    def fetch_url_from_email(email_address, url_sub_string)
      urls = URI.extract(retrieve_email_with_content(email_address, url_sub_string)["text"])
      index = urls.index { |s| s.include?(url_sub_string) }
      urls[index]
    end

    def retrieve_email_with_content(email_address, content)
      puts "Fetching email for #{email_address}
            with content #{content}
            at #{DateTime.now.strftime('%a %d %b %Y at %I:%M%p')}"
      Timeout.timeout(EMAIL_FETCHING_TIMEOUT) do
        loop do
          emails = retrieve_all_emails_for(email_address)
          emails.each { |email| return email if email["text"].include?(content) }
        end
      end
    rescue Timeout::Error
      nil
    end

    def retrieve_email_with_subject(email_address, subject)
      puts "Fetching email for #{email_address}
            with subject #{subject}
            at #{DateTime.now.strftime('%a %d %b %Y at %I:%M%p')}"
      Timeout.timeout(EMAIL_FETCHING_TIMEOUT) do
        loop do
          emails = retrieve_all_emails_for(email_address)
          emails.each { |email| return email if email["subject"].start_with?(subject) }
        end
      end
    rescue Timeout::Error
      nil
    end

    def retrieve_all_emails_for(email_address)
      TestContextManager.instance.mail_service.get_all_inbox_messages(email_address)
    end
  end
end
