# frozen_string_literal: true

require_relative "../../../components/card.rb"
require_relative "../../../components/file_upload.rb"
require_relative "../../../components/modal.rb"
require_relative "../../../components/section.rb"
require_relative "../../page.rb"

module AppPages
  # /de/app/manager/inquiries/(:?\d+)
  class ManagerInquiryDetails
    include Page
    include Components::Card
    include Components::FileUpload
    include Components::Modal
    include Components::Section

    private

    # extend Components::FileUpload ------------------------------------------------------------------------------------

    def upload_inquiry_document(_)
      selector = ".cucumber-inquiry-upload-button"
      Helpers::NavigationHelper.wait_for_resources_downloaded
      # Capybara doesn't interact with non-visible elements,
      # altering css atribute to make element visible for file selection
      page.execute_script("$('#{selector}').css('display','block')")
      page.attach_file(find(:css, selector)["id"], Helpers::OSHelper.upload_file_path("retirement_cockpit.pdf")
      )
    end

    # extend Components::Section ---------------------------------------------------------------------------------------

    # TODO: reduce usage of German in method names

    def assert_page_section(section_heading)
      Helpers::MobileBrowserHelper.open_section_if_required(section_heading)
      page.all(".cucumber__clarkordion__item__header--active").each do |section|
        return nil if section.text.include?(section_heading)
      end
      raise Capybara::ElementNotFound.new("Section #{section_heading} was not found")
    end

    def assert_allgemeine_informationen_section(_)
      assert_page_section("Allgemeine Informationen")
      expect(page).to have_selector(".cucumber__manager__product__details__stats__map")
    end

    def assert_expertentipps_zur_versicherung_section(_)
      assert_page_section("Expertentipps zur Versicherung")
      article_number = find(".cucumber-swiper-container").all(".cucumber-swiper-slide").length
      return expect(article_number).to eq(3) unless TestContextManager.instance.mobile_browser?
      expect(article_number).to eq(1)
    end

    def assert_bewertung_der_gesellschaft_section(_)
      assert_page_section("Bewertung der Gesellschaft")
      expect(page).to have_selector(".cucumber-rating-container")
    end
  end
end
