# frozen_string_literal: true

# Include this module into Wrapper class and override wrapper method
module Wrapper
  def callback
    method(:wrapper)
  end

  private

  # @abstract
  def wrapper
    raise NotImplementedError.new
  end
end
