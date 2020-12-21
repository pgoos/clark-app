# frozen_string_literal: true

require_relative "page.rb"

# Generic page
# Used as a Page Context if more specific context was not found
# DO NOT implement any methods inside this class
class GenericPage
  include Page
end
