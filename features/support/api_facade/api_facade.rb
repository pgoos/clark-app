# frozen_string_literal: true

require "faraday"
require_relative "client.rb"
require_relative "session.rb"

# Class provides the Facade for the interaction with CLARK APIs
# All clark APIs are grouped into adapters according to their versions
# Public interfaces of this Facade are designed to be understandable & usable without deep knowledge of Clark APIs
class ApiFacade
  attr_reader :session

  def initialize
    @session = Session.new
    @client = Client.new(@session)
  end

  # @return [AutomationHelpersAPIAdapter]
  def automation_helpers
    client = Client.new(@session, "automation_helpers_v1")
    @automation_helpers ||= AutomationHelpersAPIAdapter.new(client)
  end

  # @return [V2APIAdapter]
  def v2
    client = Client.new(@session, "v2")
    @v2 ||= V2APIAdapter.new(client, @session)
  end

  # @return [V4APIAdapter]
  def v4
    client = Client.new(@session, "v4")
    @v4 ||= V4APIAdapter.new(client)
  end

  # @return [WebAppAdapter]
  def web_app
    client = Client.new(@session)
    @web_app ||= WebAppAdapter.new(client)
  end
end
