# frozen_string_literal: true

require_relative "../../helpers/wrappers/wrappers"

module Components
  # This component is responsible for the interactions with different menu objects (burger menu, profile menu, etc)
  module Menu
    extend Helpers::Wrappers

    sleep_after 1, :open_cms_burger_menu, :open_profile_menu

    # Method opens target menu
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def open_profile_menu { }
    # @param marker [String] custom method marker
    def open_menu(marker)
      send("open_#{marker.tr(' ', '_')}_menu")
    end

    private

    # cross-page shared methods ----------------------------------------------------------------------------------------

    # Method open burger menu on CMS mobile pages
    def open_cms_burger_menu
      return if TestContextManager.instance.desktop_browser?
      find('button[aria-label="Navigation Menu"]').click
    end

    # Method opens Versicherungen menu [CMS pages]
    # Method hovers over button in desktop mode and clicks on a link in mobile
    def open_versicherungen_menu
      btn_text = "Versicherungen"

      # desktop version
      if TestContextManager.instance.desktop_browser?
        # HACK: a is added for the compatibility with dynamic environments
        return find("a", text: btn_text).hover if has_css?("a", text: btn_text, match: :prefer_exact, wait: 1)
        return find("button", text: btn_text).hover
      end

      # mobile version
      open_cms_burger_menu
      find("label", text: btn_text, match: :prefer_exact).click
    end

    # Method opens profile menu [EmberApp]
    # Method hovers over profile icon in desktop mode and click on burger menu icon in mobile
    def open_profile_menu
      return find("span.cucumber-user-profile").hover if TestContextManager.instance.desktop_browser? # desktop
      find("span.cucumber-menu-icon").click                                                           # mobile
    end
  end
end
