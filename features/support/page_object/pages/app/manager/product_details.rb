# frozen_string_literal: true

require_relative "../../../components/card.rb"
require_relative "../../../components/file_upload.rb"
require_relative "../../../components/list.rb"
require_relative "../../../components/scroll.rb"
require_relative "../../../components/section.rb"
require_relative "../../page.rb"

module AppPages
  # /de/app/manager/products/(:?\d+)
  class ProductDetails
    include Page
    include Components::Card
    include Components::FileUpload
    include Components::List
    include Components::Scroll
    include Components::Section

    private

    # extend Components::List ------------------------------------------------------------------------------------------

    def assert_tariff_details_list(_)
      expect(page).to have_selector(".cucumber-product-details-list")
    end

    # extend Components::Scroll ----------------------------------------------------------------------------------------

    def scroll_to_upload_documents_section
      # scroll the page to the documents upload area
      scroll_to_css ".cucumber-document-upload"
    end

    # extend Components::Section ---------------------------------------------------------------------------------------

    # TODO: reduce usage of German in method names

    def assert_header_is_visible(section_heading)
      page.all(".cucumber-heading-secondary").each do |section|
        return nil if section.text.include?(section_heading)
      end
      raise Capybara::ElementNotFound.new("Header #{section_heading} was not found")
    end

    def assert_allgemeine_informationen_section(_)
      assert_header_is_visible("Allgemeine Informationen")
      expect(page).to have_selector(".cucumber__manager__product__details__stats__map")
    end

    def assert_expertentipps_zur_versicherung_section(_)
      assert_header_is_visible("Expertentipps zur Versicherung")
      article_number = find(".cucumber-swiper-container").all(".cucumber-swiper-slide").length
      return expect(article_number).to eq(3) unless TestContextManager.instance.mobile_browser?
      expect(article_number).to eq(1)
    end

    def assert_product_clark_rating_section(_)
      assert_header_is_visible("CLARK-Rating")
      expect(page).to have_selector(".cucumber__manager__product__details__rating__container")
    end
  end
end
