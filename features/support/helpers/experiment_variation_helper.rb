# frozen_string_literal: true

module Helpers
  # Helper for setting different experiment variations.
  module ExperimentVariationHelper
    module_function
    # @param item[String] local storage item name
    # @param experiments[Hash] list of the experiments values set for the local storage item
    def set_experiments(item, experiments)
      js = "window.localStorage.setItem('#{item}', '#{experiments.to_json}')"
      Capybara.current_session.execute_script(js)
    end
  end
end
