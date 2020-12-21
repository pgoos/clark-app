# frozen_string_literal: true

require "rails_helper"

require "./spec/support/features/page_objects/ember/manager/optimization_tab_page"
require "./spec/support/features/page_objects/ember/manager/contracts_cockpit_page"
require "./spec/support/features/page_objects/ember/manager/pre_demandcheck_page"
require "./spec/support/features/page_objects/ember/demandcheck/demandcheck_page"
require "./spec/support/features/page_objects/ember/rate-us/page"

RSpec.describe "Optimization Tabs without DC", :browser, type: :feature, js: true do
  before do
    require(Core::Seeder.development_seed_path_for("08_bedarfcheck_questionnaire"))
    categories_config = YAML.load(File.read(Rails.root.join("db", "fixtures", "categories.yml")))

    categories_config.each do |config|
      if Domain::DemandCheck::DemandCheckHelper::CATEGORY_IDENTS.include?(config["ident"])
        category = Category.create(config.except("id"))
        category.vertical = Vertical.find_or_create_by!(name: "some vertical")
        category.save!
      end
    end
    create(:inquiry, mandate: user.mandate, categories: [Category.gkv])
    create(
      :questionnaire_response,
      mandate:       mandate,
      questionnaire: bedarfcheck_questionnaire
    )
  end

  let(:locale)                    { I18n.locale }
  let!(:demandcheck_page)         { DemandCheckPage.new }
  let!(:optimization_page_object) { OptimizationTab.new }
  let!(:contracts_cockpit_page)   { ContractsCockpit.new }
  let!(:pre_demand_check_page)    { PreDemandCheckPage.new }
  let!(:rate_us_page)             { RateUsPage.new }

  let!(:user) { create(:user, mandate: create(:mandate)) }

  let!(:mandate) do
    mandate = user.mandate
    mandate.signatures.create(
      asset: Rack::Test::UploadedFile.new(
        Core::Fixtures.fake_signature_file_path
      )
    )
    mandate.info["wizard_steps"] = %w[targeting profiling confirming]
    mandate.tos_accepted_at      = 1.minute.ago
    mandate.confirmed_at         = 1.minute.ago
    # so they do not get retirement CTA's
    mandate.birthdate            =  Time.zone.now - 70.years
    mandate.state                = "created"
    mandate.save!
    mandate
  end

  let(:bedarfcheck_questionnaire) do
    Questionnaire.find_by!(identifier: Questionnaire::BEDARFCHECK_IDENT)
  end

  context "visit cockpit and starts bedafscheck" do
    let(:questionnaire) { create(:questionnaire, identifier: Questionnaire::RETIREMENTCHECK_IDENT) }

    before do
      # So the user does not get the CTA's to start the retirement flow
      create(:questionnaire_response, questionnaire: questionnaire, mandate: user.mandate, state: :completed)
      user.mandate.info["positive_rating_selected"] = true
      user.mandate.info["positive_rating_selected_timestamp"] = Time.current
      login_as(user, scope: :user)
      contracts_cockpit_page.visit_page
      allow_any_instance_of(Mandate).to receive(:primary_phone_verified).and_return(true)
    end

    scenario "correctly completes the flow", skip: "https://clarkteam.atlassian.net/browse/JCLARK-50136" do
      rate_us_page.close_rating_modal
      optimization_page_object.close_demandcheck_reminder_modal
      Capybara.current_session.execute_script "window.localStorage.setItem('reminders-since-mandate', 3);"
      contracts_cockpit_page.expect_skeleton_gone
      contracts_cockpit_page.click_start_bedarfscheck
      Capybara.current_session.execute_script "window.localData.setAttr('manager', 'numOneRecModalShown', true);"
      pre_demand_check_page.click_start_bedarfscheck

      demandcheck_page.answer_demandcheck

      optimization_page_object.expect_no_skeleton
      optimization_page_object.optimization_page_visited
      optimization_page_object.has_title("Deine Optimierungsmöglichkeiten")
      optimization_page_object.has_three_verticals(
        "Besitz & Eigentum", "Gesundheit & Existenz", "Altersvorsorge"
      )

      optimization_page_object.has_vertical_scores("0/5", "1/4", "0/1")

      optimization_page_object.bottom_link_text(
        "Falls sich deine Lebenssituation verändert hat, solltest du den Bedarfscheck aktualisieren. Bedarfscheck starten"
      )

      # optimization_page_object.importance_info_for_verticals(
      #   "Wichtig", "Sinnvoll", "Sinnvoll", "Sinnvoll", "Sinnvoll", "Wichtig", "Sinnvoll", "Sinnvoll", "Sinnvoll", "Wichtig", "Sinnvoll", "Sinnvoll"
      # )

      optimization_page_object.click_vertical_one_info
      optimization_page_object.vertical_one_has_info_text(
        "Dieser Bereich schützt dich vor hohen Kosten, die auf dich zukommen, " \
        "wenn teure Dinge von dir oder anderen kaputtgehen und repariert oder ersetzt werden müssen."
      )
      optimization_page_object.vertical_one_info_has_percentage_info(
        "Basierend auf deiner Lebenssituation empfehlen die #{I18n.t('.owner_ident')} Experten, " \
        "die angegebenen Versicherungen zu haben. Die Empfehlungen orientieren sich " \
        "an Branchenstandards und Empfehlungen des Verbraucherschutzes."
      )

      optimization_page_object.vertical_one_hide_info
      optimization_page_object.expect_cta_for_add_offer_works
    end
  end
end
