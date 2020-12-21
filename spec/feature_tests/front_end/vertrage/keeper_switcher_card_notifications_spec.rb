require "rails_helper"
require "./spec/support/features/page_objects/ember/manager/keeper_switcher_page"

# TODO: find out if we can remove this file

RSpec.describe "Keeper switcher card notifications", :browser, type: :feature, js: true, skip: true do

  let(:locale) { I18n.locale }

  before do
    allow_any_instance_of(Mandate).to receive(:done_with_demandcheck?).and_return(true)
  end

  # Page objects
  let!(:switcher_page) { KeeperSwitcherPage.new }
  let!(:bu_category) { create(:bu_category) }
  let!(:inquiry_category) { create(:inquiry_category, category: bu_category) }
  let!(:bu_inq) { create(:inquiry, inquiry_categories: [inquiry_category], mandate: user.mandate) }

  let!(:sparen_rule) { "2.4" }
  let!(:default_rule) { "2.3" }
  let!(:leistung_rule) { "2.1" }

  let!(:user) do
    user = create(:user, confirmation_sent_at: 2.days.ago, mandate: create(:mandate))
    user.mandate.info["wizard_steps"] = ["profiling", "targeting", "confirming"]
    user.mandate.signature = create(:signature)
    user.mandate.confirmed_at = DateTime.current
    user.mandate.tos_accepted_at = DateTime.current
    # In creation so we don't get the add more insurances modal
    user.mandate.state = :in_creation
    user
  end

  let!(:category_questionnaire) { create(:questionnaire) }
  let!(:category) { create(:category, questionnaire: category_questionnaire) }
  let!(:category_questionnaire_plan) { create(:plan, category: category, company: create(:company)) }


  context "having done a questionniare for a switcher" do
    let!(:questionnaire_response) {
      create(:questionnaire_response,
                        mandate: user.mandate,
                        questionnaire: category_questionnaire,
                        state: "completed",
                        created_at: 1.year.ago)
    }
    let!(:product) {
      create(
          :product,
          plan: category_questionnaire_plan,
          mandate: user.mandate
      ) }
    let!(:advice) { create(:advice, product: product, rule_id: "bad") }

    before do
      login_as(user, scope: :user)
      switcher_page.visit_page
    end

    it "should show no switcher message" do
      switcher_page.expect_no_switcher_message(product.id)
    end

  end

  context "having not done a questionnaire for a switcher" do
    let!(:product) {
      create(
        :product,
        plan: category_questionnaire_plan
      )
    }
    let!(:advice) { create(:advice, product: product, rule_id: "bad") }

    before do
      login_as(user, scope: :user)
      switcher_page.visit_page
    end

    it "should show no switcher message" do
      switcher_page.expect_no_switcher_message(product.id)
    end
  end

  context "having started a qustioannire for a switcher" do
    let!(:questionnaire_response) {
      create(:questionnaire_response,
                        mandate: user.mandate,
                        questionnaire: category_questionnaire,
                        state: "in_progress",
                        created_at: 1.year.ago)
    }

    let!(:product) {
      create(
        :product,
        plan: category_questionnaire_plan,
        mandate: user.mandate
      )
    }

    let!(:advice) { create(:advice, product: product, rule_id: "bad") }

    before do
      login_as(user, scope: :user)
      switcher_page.visit_page
    end

    it "should not show the switcher message" do
      switcher_page.expect_no_switcher_message(product.id)
    end
  end

  context "not started a questionnaire or finsihed one" do
    let!(:product) {
      create(
        :product,
        plan: category_questionnaire_plan,
        mandate: user.mandate
      )
    }

    context "just as a switcher keeper" do
      let!(:advice) { create(:advice, product: product, rule_id: "bad", metadata: { "identifier": "keeper_switcher"}) }

      before do
        login_as(user, scope: :user)
        switcher_page.visit_page
      end

      it "should show the switcher message" do
        switcher_page.expect_switcher_unknown_message(product.id)
      end
    end

    context "with an advice rule that is in the list as leistung" do
      let!(:advice) { create(:advice, product: product, rule_id: leistung_rule, metadata: { "identifier": "keeper_switcher"}) }

      before do
        login_as(user, scope: :user)
        switcher_page.visit_page
      end

      it "should show the leisting message" do
        switcher_page.expect_switcher_leistung_message(product.id)
      end
    end

    context "with an advice rule that is in the list as default" do
      let!(:advice) { create(:advice, product: product, rule_id: default_rule, metadata: { "identifier": "keeper_switcher"}) }

      before do
        login_as(user, scope: :user)
        switcher_page.visit_page
      end

      it "should show the default message" do
        switcher_page.expect_switcher_default_message(product.id)
      end
    end

    context "with an advice rule that is in the list as sparen" do
      let!(:advice) { create(:advice, product: product, rule_id: sparen_rule, metadata: { "identifier": "keeper_switcher"}) }

      before do
        login_as(user, scope: :user)
        switcher_page.visit_page
      end

      it "should show the sparen message" do
        switcher_page.expect_switcher_sparen_message(product.id)
      end
    end


    context "with an advice that had an old classification ident as sparen but a rule id as default" do
      let!(:advice) { create(:advice, product: product, rule_id: sparen_rule, metadata: { "identifier": "keeper_switcher", "classifications": [default_rule]}) }

      before do
        login_as(user, scope: :user)
        switcher_page.visit_page
      end

      it "should show the default message" do
        switcher_page.expect_switcher_default_message(product.id)
      end
    end

    context "with an advice that has more than one classificaiton rule ident" do
      let!(:advice) { create(:advice, product: product, rule_id: leistung_rule, metadata: { "identifier": "keeper_switcher", "classifications": [default_rule, sparen_rule]}) }

      before do
        login_as(user, scope: :user)
        switcher_page.visit_page
      end

      it "should use the last and show the sparen message" do
        switcher_page.expect_switcher_sparen_message(product.id)
      end
    end

    context "if keeper switcher but no rule id OR classification id in the array, should ude leistung message" do
      let!(:advice) { create(:advice, product: product, rule_id: "bad", metadata: { "identifier": "keeper_switcher", "classifications": ["NOTHING"]}) }

      before do
        login_as(user, scope: :user)
        switcher_page.visit_page
      end

      it "should use the fist and show the sparen message" do
        switcher_page.expect_switcher_unknown_message(product.id)
      end
    end
  end
end


