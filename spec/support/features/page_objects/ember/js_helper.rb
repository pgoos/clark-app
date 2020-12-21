require 'capybara-screenshot/rspec'

RSpec::Matchers.define :jquery_have_selector do |selector|
  match do |page|
    @errors = {}
    @errors = "Cannot find #{selector}" unless JsHelper.have_selector(page, selector)
    @errors.empty?
  end
end

class JsHelper
  class << self
    def run_js(page, script)
      page.evaluate_script(script)
    rescue => e
      puts "Cannot run JS! #{e.message}"
    end

    def disable_animations(page)
      run_js(page, "$.Velocity.mock = true")
      run_js(page, "$.fx.off = true")
    end

    def wait_for_ember(page)
      wait_for_ajax(page)
      wait_for_loop(page)
    end

    # Ugh Refactor that
    def wait_for_ajax(page)
      ajax_check_js = "jQuery.active"
      Timeout.timeout(Capybara.default_max_wait_time) do
        active = run_js(page, ajax_check_js)
        active = run_js(page, ajax_check_js) until active == 0
      end
    end

    def wait_for_loop(page)
      ember_loop = "(typeof Ember === 'object') && !Ember.run.hasScheduledTimers() && !Ember.run.currentRunLoop"

      counter = 0
      while true
        queue_complete = run_js(page, ember_loop)

        break if queue_complete
        counter += 1
        sleep(0.1)
        raise "Ember Loop did not finished after 5s" if counter >= 50
      end
    end

    def wait_for_element(page, element)
      counter = 0
      while true
        selector = have_selector(page, element)
        puts selector

        break if selector
        counter += 1
        sleep(0.1)
        raise "Element was not found after 5s" if counter >= 50
      end
    end

    def timeout_or_error
      "AJAX request took longer than 5 seconds
      OR there was a JS error. Check your console."
    end

    def cheese(context)
      context.screenshot_and_save_page
    end

    def jQuery(page, cmd)
      run_js(page, "$#{cmd}; true")
    end

    def have_selector(page, selector)
      run_js(page, "$('#{selector}').length").to_i != 0
    end

    def debug_with_chrome
      Capybara.register_driver :chrome do |app|
        caps = Selenium::WebDriver::Remote::Capabilities.chrome(
          chromeOptions: {args: %w[incognito window-size=2000,2000]}
        )
        Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: caps)
      end
      Capybara.javascript_driver = :chrome
    end

    def debug_with_headless_chrome
      Capybara.javascript_driver = :selenium_chrome
    end

    def wait_forever
      sleep 60 * 1000
    end

    def sample_iban
      # keeping in lower case for debug_with_chrom, as it doesn't run properly in chrome for some unknown reason
      "de27100777770209299700".freeze
    end
  end
end
