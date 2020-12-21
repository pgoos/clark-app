# frozen_string_literal: true

module Components
  # This component is responsible for interactions with labels
  module Label
    # Method asserts that page contains target label
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def assert_category_title_label(label) { }
    # @param marker [String] custom method marker
    # @param label [String] concrete label sign
    def assert_label(marker, label=nil)
      send("assert_#{marker.tr(' ', '_')}_label", label)
    end

    private

    # cross-page shared methods ----------------------------------------------------------------------------------------

    # method asserts current registration step number in mandate funnel related pages
    # @param label [String] step number. Must be in format 'N of N'. Example: 1 of 5
    def assert_step_number_label(label)
      current_step, total_steps = label.split(" of ")
      expect(find("div.cucumber-mandate-registration-step-number").text).to eq("#{current_step} /#{total_steps}")
    end
  end
end
