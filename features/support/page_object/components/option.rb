# frozen_string_literal: true

module Components
  # This component provides interface(s) for performing interactions with options on (questionnaire, targeting, etc) pages
  module Option
    # @abstract
    # Method selects option
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def select_category_option(option, is_suboption) { }
    # @param option [String, nil] option value
    # @param is_suboption [String, nil] if present, suboption will be selected
    def select_option(marker, option, is_suboption=nil)
      send("select_#{marker.tr(' ', '_')}_option", option, is_suboption)
      sleep 0.25
    end

    # @abstract
    # Method selects options
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def select_category_options(is_suboption, table) { }
    # @param table [Cucumber::Ast::Table, nil] table of options
    # @param is_suboption [String, nil] if present, suboption will be selected
    def select_options(marker, table, is_suboption=nil)
      send("select_#{marker.tr(' ', '_')}_options", table, is_suboption)
      sleep 0.25
    end
  end
end
