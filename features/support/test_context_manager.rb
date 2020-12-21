# frozen_string_literal: true

require "singleton"
require "base64"
require_relative "service/fake_smtp_service/fake_smtp_service_factory.rb"
require_relative "service/letter_opener_service/letter_opener_service_factory.rb"

# This class receives, stores and provides information about Test Execution Context
class TestContextManager
  include Singleton

  attr_reader :target_url,
              :locale,
              :driver,
              :selenium_hub_ip,
              :http_auth_username,
              :http_auth_password,
              :mail_service,
              :sms_service,
              :enabled_proxy

  def initialize
    @target_url = ENV.fetch("CUCUMBER_TARGET_URL")
    @locale = ENV.fetch("APP_LOCALE", "default")
    @driver = ENV.fetch("CAPYBARA_DRIVER", "chrome").to_sym
    @selenium_hub_ip = ENV.fetch("SELENIUM_HUB_IP", nil)
    @enable_tracking_scripts = (ENV["ENABLE_TRACKING_SCRIPTS"] == "true")
    @http_auth_username = ENV.fetch("CUCUMBER_HTTP_AUTH_USERNAME", "clark")
    @http_auth_password = provide_http_password
    @enabled_proxy = (ENV["USE_PROXY"] == "true")
    factory = initialize_fake_smtp_service
    # @type [IServiceFactory]
    @sms_service = factory.sms_service
    # Suppress warnings in order not to pollute stdout which tests expectations rely on
    $VERBOSE = nil if ENV.fetch("CUCUMBER_VERBOSE", "silent")
  end

  def staging?
    %w[https://staging.clark.de https://staging.clark-de.flfinteche.de].include? @target_url
  end

  def staging_2_20?
    @target_url.include?("staging-test")
  end

  def local?
    @target_url.include?("development")
  end

  def mobile_browser?
    # TODO: find hardcodeless solution
    %i[chrome_iphone_x headless_chrome_iphone_x].include? @driver
  end

  def ie_browser?
    [:remote_ie].include? @driver
  end

  def desktop_browser?
    !mobile_browser?
  end

  def enable_tracking_scripts?
    @enable_tracking_scripts
  end

  def austria?
    @locale == "de-at"
  end

  def mandate_helper
    austria? ? Helpers::MandateHelpers::AustriaMandateHelper.new : Helpers::MandateHelpers::ClarkMandateHelper.new
  end

  private

  def provide_http_password
    default = nil
    if austria?
      default = "et6SYsGLU5WG2dLCUUv^RT$uTRaMPM@RpUF^ztXMz05tGFIemq"
    elsif staging?
      default = "We-L0ve-Insurance"
    else
      default = "clarkkent"
    end
    ENV.fetch("CUCUMBER_HTTP_AUTH_PASSWORD", default)
  end

  def initialize_fake_smtp_service
    @fakesmtp_url = ENV.fetch("FAKESMTP_URL", nil)
    if @fakesmtp_url != nil
      @fakesmtp_auth_username = ENV.fetch("FAKESMTP_AUTH_USERNAME", "")
      @fakesmtp_auth_password = Base64.decode64(ENV.fetch("FAKESMTP_AUTH_PASSWORD", ""))
      factory = FakeSMTPServiceFactory.new(@fakesmtp_auth_username, @fakesmtp_auth_password, @fakesmtp_url)
      @mail_service = factory.mail_service
    else
      factory = LetterOpenerServiceFactory.new
    end
    factory
  end
end
