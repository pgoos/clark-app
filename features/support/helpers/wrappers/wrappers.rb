# frozen_string_literal: true

require_relative "handle_webdriver_errors_wrapper"
require_relative "sleep_after_wrapper"

module Helpers
  # This module is a collection of method wrappers
  module Wrappers
    def handle_webdriver_errors(*methods)
      wrap_methods(HandleWebdriverErrorsWrapper.new.callback, methods)
    end

    def sleep_after(sleep_time, *methods)
      wrap_methods(SleepAfterWrapper.new(sleep_time).callback, methods)
    end

    private

    # Method wraps provided list of methods
    # @param callback [Method] wrapper method. Should contain yield keyword
    # @param method_names [Array] array of names of the methods to be wrapped
    def wrap_methods(callback, method_names)
      wrapper = Module.new do
        method_names.each do |method_name|
          define_method(method_name) { |*args| callback.call { super(*args) } }
        end
      end
      prepend wrapper
    end
  end
end
