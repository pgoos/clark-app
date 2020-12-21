# frozen_string_literal: true

require_relative "letter_opener_sms_service.rb"

class LetterOpenerServiceFactory
  def sms_service
    LetterOpenerSmsService.new
  end
end
