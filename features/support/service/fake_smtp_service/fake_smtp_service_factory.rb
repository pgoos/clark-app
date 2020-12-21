# frozen_string_literal: true

require_relative "fake_smtp_http_client"
require_relative "fake_smtp_mail_service"
require_relative "fake_smtp_sms_service"

class FakeSMTPServiceFactory
  def initialize(user_name, password, url)
    @connection = FakeSMTPHTTPClient.new(user_name, password, url)
  end

  def mail_service
    @mail_service ||= FakeSTMPMailService.new(@connection)
  end

  def sms_service
    @sms_service ||= FakeSMTPSMSService.new(@connection)
  end
end
