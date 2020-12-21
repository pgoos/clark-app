# frozen_string_literal: true

require_relative "../page.rb"
require_relative "questionnaire.rb"

module AppPages
  # de/app/demandcheck/intro
  class DemandCheck < Questionnaire
    include Page
  end
end
