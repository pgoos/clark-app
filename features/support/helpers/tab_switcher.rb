# frozen_string_literal: true

module Helpers
  # This helper is responsible for switching browser tabs
  # TODO: Maybe we can create tabs context manager, so these actions from methods below can be handled in better way
  module TabSwitcher
    module_function

    # Method opens new browser tab and switches to it
    def switch_to_next_tab
      number_of_open_windows = Capybara.current_session.windows.length
      if number_of_open_windows == 1
        # open new tab
        Capybara.current_session.switch_to_window(Capybara.current_session.open_new_window)
      else
        # go to second tab
        Capybara.current_session.switch_to_window(Capybara.current_session.windows.last)
      end
    end

    # Module switches browser to the first tab
    def switch_to_first_tab
      # go to first tab
      Capybara.current_session.switch_to_window(Capybara.current_session.windows.first)
    end
  end
end
