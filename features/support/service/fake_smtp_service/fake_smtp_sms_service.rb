# frozen_string_literal: true

class FakeSMTPSMSService
  SMS_RECEIVER = "fake@email.com"
  def initialize(connection)
    @connection = connection
  end

  def get_verification_token(phone_number)
    token ||= []
    @connection.execute_http_request(SMS_RECEIVER).each do |resp|
      token.push(resp["text"].scan(/\b\d{4}\b/)) if resp["text"].include?(phone_number)
    end
    token.first.join
  end

  private_constant :SMS_RECEIVER
end
