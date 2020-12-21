# frozen_string_literal: true

require_relative "../../helpers/wrappers/wrappers"

module Components
  # This component is responsible for interactions with links
  module Link
    extend Helpers::Wrappers

    handle_webdriver_errors :click_on_link, :hover_over_link
    sleep_after 0.25, :click_on_link, :hover_over_link

    # Method clicks on the link.
    # Searches for the link by provided text
    # Can handle 'a', 'span' and 'label' links
    # Scrolls to the link if scroll_to is true
    # @param text [String] link text
    def click_on_link(text, scroll_to=false)
      if has_css?("a", text: text, match: :prefer_exact, wait: 1)
        link_type = "a"
      elsif has_css?("span", text: text, match: :prefer_exact, wait: 1)
        link_type = "span"
      elsif has_css?("label", text: text, match: :prefer_exact, wait: 1)
        link_type = "label"
      else
        raise Capybara::ElementNotFound.new("Can't find link with '#{text}' text")
      end

      if scroll_to
        js_scroll_script = "arguments[0].scrollIntoView(true);"
        Capybara.page.execute_script(js_scroll_script, find(link_type, text: text, match: :prefer_exact))
        sleep 0.5
      end

      find(link_type, text: text, match: :prefer_exact).click
    end

    # Method hovers over the link.
    # Searches for the link by provided text
    # Can handle 'a' links only
    # @param text [String] link text
    def hover_over_link(text)
      find("a", text: text).hover
    end

    # Method asserts that link is visible
    # @param text [String] link text
    # @param is_target_link [String, nil] if value is provided, will check that target link is present
    # @param link [String] if value is provided, will check that link with this href is present
    def assert_link_is_visible(text, is_target_link=nil, link=nil)
      if !is_target_link.nil?
        find_link(text, visible: true)[:target].should == "_blank"
      elsif !link.nil?
        expect(page).to have_link(text, visible: true, href: Helpers::ContentHelper.str_to_regexp(link), minimum: 1)
      else
        expect(page).to have_link(text, visible: true, minimum: 1)
      end
    end

    # Method asserts a page contains no target link
    # Custom method can be implemented. Example: def assert_product_link_is_not_visible() { }
    # @param text [String] link text
    # @param link [String] if value is provided, will check that link with this href is not present
    def assert_link_is_not_visible(text, link)
      # dispatch
      custom_method = "assert_#{text.tr(' ', '_')}_link_is_not_visible"
      return send(custom_method) if respond_to?(custom_method, true)

      # default generic implementation
      if link.nil?
        expect(page).not_to have_link(text, visible: true, wait: 3)
      else
        expect(page).not_to have_link(text, visible: true, wait: 3, href: Helpers::ContentHelper.str_to_regexp(link))
      end
    end
  end
end
