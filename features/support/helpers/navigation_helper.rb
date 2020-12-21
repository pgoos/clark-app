# frozen_string_literal: true

module Helpers
  module NavigationHelper
    module_function

    def navigate_to_page(page_alias)
      unless Repository::PathTable.page_navigable?(page_alias)
        raise ArgumentError.new("Page #{page_alias} is not navigable, contains regular expression in Path Table.")
      end
      page_url = Repository::PathTable[page_alias]
      Capybara.current_session.visit(page_url)
    end

    def navigate_to_url(page_url)
      Capybara.current_session.visit(page_url)
    end

    def refresh_page
      Capybara.current_session.driver.browser.navigate.refresh
    end

    # 'window.performance.getEntries()' returns an array of PerformanceResourceTiming items.
    # Every finished resource network request appends new PerformanceResourceTiming to this array.
    # Method waits until length of this array is constant during quiet_period seconds
    # TODO: Find alternative way to track loaded resources
    def wait_for_resources_downloaded(quiet_period=3)
      js_script = "window.performance.getEntries().length"
      sleep 1
      Timeout.timeout(Capybara.default_max_wait_time) do
        resources_len = Capybara.current_session.evaluate_script(js_script)
        waiting_end_time = Time.now.utc + quiet_period

        while Time.now.utc < waiting_end_time
          resources_len_actual = Capybara.current_session.evaluate_script(js_script)
          sleep 0.5
          next if resources_len_actual == resources_len
          resources_len = resources_len_actual
          waiting_end_time = Time.now.utc + quiet_period
        end
      end
    end
  end
end
