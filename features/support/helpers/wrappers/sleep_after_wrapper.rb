# frozen_string_literal: true

require_relative "wrapper"

# Wrapper sleeps specified amount of time after wrapped method is executed
class SleepAfterWrapper
  include Wrapper

  # @param sleep_time [Integer] sleep time in seconds
  def initialize(sleep_time)
    @sleep_time = sleep_time
  end

  private

  def wrapper
    yield
    sleep(@sleep_time)
  end
end
