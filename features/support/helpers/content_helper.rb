# frozen_string_literal: true

module Helpers
  module ContentHelper
    module_function

    def str_to_regexp(str)
      Regexp.new(Regexp.quote(str))
    end
  end
end
