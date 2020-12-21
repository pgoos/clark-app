# frozen_string_literal: true

module Helpers
  module OpsUiHelper
    extend self

    class TableHelper
      # class for working with tables in OPS UI
      include Capybara::DSL

      def initialize(options={})
        # node(ELEMENT), parent_id or table_class is required
        if options.include? :node
          table = options[:node]
        elsif options.include? :parent_id
          table = page.find("##{options[:parent_id]}", visible: :all).find(:css, "table", visible: :all)
        elsif options.include? :table_class
          table = find(options[:table_class])
        else
          raise ArgumentError.new("One of three options is required - node, parent_id or table_class")
        end

        @body = table.first(:css, "tbody", visible: :all)
        @head = table.has_css?("thead", wait: 0.5) ? table.find(:css, "thead", visible: :all) : nil
      end

      def row(row_number)
        @body.all(:css, "tr")[row_number]
      end

      def row_text(row_number)
        row(row_number).text
      end

      def cell(row_number, column_number)
        row(row_number).all(:css, "td")[column_number]
      end

      def cell_text(row_number, column_number)
        cell(row_number, column_number).text
      end

      def link(row_number, column_number)
        cell(row_number, column_number).first(:css, "a")
      end

      def link_text(row_number, column_number)
        link(row_number, column_number).text
      end

      def rows_number
        @body.all(:css, "tr").size
      end

      def find_row_number_by_text(text)
        (0...rows_number).each do |row_number|
          return row_number if row_text(row_number).include?(text)
        end
        raise Capybara::ElementNotFound.new("Row with provided text was not found")
      end

      # click on link in a column by text on another column of the same row
      # @param link_column [Integer] - number of column with link
      # @param target_column [Integer] - number of column with text
      # @param text [String] text in target column
      def click_by_text_in_row(link_column, target_column, text)
        (0...rows_number).each do |row_number|
          return link(row_number, link_column).click if cell_text(row_number, target_column) == text
        end
        raise Capybara::ElementNotFound.new("Cell with provided text '#{text}' was not found")
      end

      def get_button_by_text_in_row(button_column, target_column, text)
        (0...rows_number).each do |row_number|
          return cell(row_number, button_column).first(".btn") if cell_text(row_number, target_column) == text
        end
        raise Capybara::ElementNotFound.new("Button in row with provided text was not found")
      end
    end

    def select_combobox_option(combobox_id, option)
      # ComboBoxes in OPS UI can't be handled in standard Capybara's way (page.select). Here is workaround helper
      Capybara.current_session.first("##{combobox_id}_chosen").click
      Capybara.current_session
              .first("##{combobox_id}_chosen")
              .first("input.chosen-search-input")
              .send_keys(option)
      sleep 1 # wait for filtering and animation
      Capybara.current_session.find("li", text: /^#{Regexp.quote(option)}$/).click
    end

    def get_combobox_option(combobox_id)
      Capybara.current_session.first("##{combobox_id}_chosen").first("span").text
    end

    def select_select2_option(combobox_id, option)
      Capybara.current_session.find("##{combobox_id} ~ span.select2").click
      Capybara.current_session.find(".select2-search__field").set(option)
      Capybara.current_session.find(".select2-results__option--highlighted").click
    end

    def get_panel_row_text(panel_heading, row_number)
      panel = nil
      Capybara.current_session.all("div.card-header").each do |section|
        if section.text.include?(panel_heading)
          panel = section
          break
        end
      end
      raise Capybara::ElementNotFound.new("Panel #{panel_heading} was not found") if panel.nil?
      TableHelper.new(node: panel.find(:xpath, "..").find(:css, "table", visible: :all)).row_text(row_number)
    end

    def refresh_if_failed
      max_refresh = 5
      refresh_count = 0
      max_refresh.times do
        yield
        break
      rescue Capybara::ElementNotFound => e
        refresh_count += 1
        max_refresh > refresh_count ? Capybara.page.refresh : raise(e)
      end
    end
  end
end
