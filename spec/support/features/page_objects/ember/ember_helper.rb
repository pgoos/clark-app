require_relative 'js_helper'

class EmberHelper < PageObject

  def ember_transition_click(btn)
    set_up_ember_transition_hook
    btn.click
    wait_for_ember_transition
  end

  def set_up_ember_transition_hook
    # Set up the hook for when the page has transitioned
    Capybara.current_session.execute_script "window.clark.webapp.capybaraTransitoned = false; window.clark.webapp.capybaraTransitionHook = function() {window.clark.webapp.capybaraTransitoned = true;}"
  end

  def wait_for_ember_transition
    25.times do
      return if Capybara.current_session.evaluate_script "window.clark.webapp.capybaraTransitoned"
      sleep 0.2
    end
  end
end
