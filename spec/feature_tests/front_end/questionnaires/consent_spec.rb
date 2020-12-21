# frozen_string_literal: true

require "rails_helper"
require "./spec/support/features/page_objects/ember/questionnaire/questionnaire_page_object"



RSpec.describe "Questionannire - consent section - CLARK", :browser, type: :feature, js: true do
  let(:locale) { I18n.locale }
  let!(:qs_po) { QuestionnairePageObject.new }

  let!(:user_accepted) do
    user = create(:user)
    user.update_attributes(mandate: create(:mandate))
    user.mandate.signature = create(:signature)
    user.mandate.confirmed_at = DateTime.current
    user.mandate.tos_accepted_at = DateTime.current
    user.mandate.health_consent_accepted_at = DateTime.current
    user.mandate.info["wizard_steps"] = %w[profiling targeting confirming]
    user.mandate.save!
    user
  end

  let!(:user_not_accepted) do
    user = create(:user)
    user.update_attributes(mandate: create(:mandate))
    user.mandate.signature = create(:signature)
    user.mandate.confirmed_at = DateTime.current
    user.mandate.tos_accepted_at = DateTime.current
    user.mandate.info["wizard_steps"] = %w[profiling targeting confirming]
    user.mandate.save!
    user
  end

  let!(:high_margin_cat) {
    create(:category, ident: "350e7cf9")
  }
  let!(:low_margin_cat) {
    create(:category, ident: "47a1b441")
  }
  let!(:correct_id_cat) {
    create(:category, id: "55")
  }

  context "User who DID NOT accept health terms" do
    before do
      login_as(user_not_accepted, scope: :user)
    end

    context "Questionnaire is high margin" do
      let(:questionnaire) {
        create(:questionnaire, category: high_margin_cat)
      }

      before do
        qs_po.visit_by_id(questionnaire.identifier)
      end

      # TODO: JCLARK-60698
      xit "should show" do
        qs_po.expect_consent_section
        qs_po.click_consent_link
        qs_po.expect_consent_modal
      end
    end

    context "Questionnaire category has the right id" do
      let(:questionnaire) {
        create(:questionnaire, category: correct_id_cat)
      }

      before do
        qs_po.visit_by_id(questionnaire.identifier)
      end

      xit "should show" do
        qs_po.expect_consent_section
      end
    end

    context "not correct id and not high margin" do
      let(:questionnaire) {
        create(:questionnaire, category: low_margin_cat)
      }

      before do
        qs_po.visit_by_id(questionnaire.identifier)
      end

      xit "should show" do
        qs_po.expect_no_consent_section
      end
    end
  end

  context "User who DID accept health terms" do
    before do
      login_as(user_accepted, scope: :user)
    end

    context "Questionnaire is high margin" do
      let(:questionnaire) {
        create(:questionnaire, category: high_margin_cat)
      }

      before do
        qs_po.visit_by_id(questionnaire.identifier)
      end

      xit "should not show" do
        qs_po.expect_no_consent_section
      end
    end

    context "Questionnaire cat has the right id" do
      let(:questionnaire) {
        create(:questionnaire, category: correct_id_cat)
      }

      before do
        qs_po.visit_by_id(questionnaire.identifier)
      end

      xit "should not show" do
        qs_po.expect_no_consent_section
      end
    end
  end
end
