# frozen_string_literal: true

require "http"

# Class stores a session's state - cookies, csrf token, current user info
class Session
  attr_accessor :cookie_jar, :current_user, :csrf_token

  def initialize
    @cookie_jar = HTTP::CookieJar.new
    @csrf_token = nil
    @current_user = {}
  end

  # @return [String]
  def current_user_mandate_id
    raise "Can't obtain mandate id for the empty current user" if current_user.empty?
    current_user["lead"]["mandate"]["id"]
  end

  # method resets the state of the current session
  def restart
    initialize
  end
end
