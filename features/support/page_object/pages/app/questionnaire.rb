# frozen_string_literal: true

require_relative "../../components/calendar.rb"
require_relative "../../components/checkbox.rb"
require_relative "../../components/icon.rb"
require_relative "../../components/label.rb"
require_relative "../../components/option.rb"
require_relative "../../components/modal.rb"
require_relative "../page.rb"

module AppPages
  # /de/app/questionnaire/(:?.+)
  class Questionnaire
    include Page
    include Components::Calendar
    include Components::Checkbox
    include Components::Icon
    include Components::Label
    include Components::Option
    include Components::Modal

    private

    # extend Components::Checkbox ------------------------------------------------------------------------------------------

    def select_health_consent_checkbox
      find("span[id*='consent-health']").click
    end

    def select_broker_consent_checkbox
      find("span[id*='consent-broker']").click
    end

    # extend Components::Icon ------------------------------------------------------------------------------------------

    def assert_consent_trust_icons(icons_number)
      expect(all("div[data-test-offers-consent-screen-trust-icons] img").length).to eq(icons_number)
    end

    # extend Components::Input -----------------------------------------------------------------------------------------

    def enter_value_into_answer_input_field(answer)
      find(".cucumber-text-input", visible: true).set(answer)
      sleep 1
    end

    def enter_value_into_birth_date_input_field(birth_date)
      page.find("#mandate_birthdate").send_keys(birth_date)
    end

    # extend Components::Label -----------------------------------------------------------------------------------------

    def assert_consent_title_label(title_text)
      expect(page).to have_css("h1[data-test-offers-consent-screen-header-title]", shy_normalized_text: title_text)
    end

    def assert_consent_subtitle_label(subtitle_text)
      css = "p[data-test-offers-consent-screen-header-sub-title]"
      expect(page).to have_css(css, shy_normalized_text: subtitle_text)
    end

    def assert_questionnaire_intro_label(questionnaire_name)
      expect(page).to have_css("p.cucumber-questionnaire-intro-header", shy_normalized_text: questionnaire_name)
    end

    def assert_question_label(question_text)
      expect(page).to have_text(question_text)
      sleep 1
    end

    # extend Components::Option ----------------------------------------------------------------------------------------

    def select_questionnaire_option(option, is_suboption)
      classname = is_suboption.nil? ? "li" : "li li"
      page.find(classname, text: option, match: :prefer_exact).click
    end

    def select_questionnaire_options(table, is_suboption)
      table.rows.each do |row|
        select_questionnaire_option(row[0], is_suboption) unless row[0].empty?
      end
    end

    # extend Components::StartScreen -----------------------------------------------------------

    def close_health_notification_modal
      find("button[data-test-modal-button-close]").click
    end
  end
end
