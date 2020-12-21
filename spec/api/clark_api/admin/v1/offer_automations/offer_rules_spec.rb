# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Admin::V1::OfferAutomations::OfferRules, :integration do
  let(:admin) { create(:admin, role: create(:role)) }
  let(:question1_ident) { "ident_1" }
  let(:selection1) { "Value 1.1" }
  let(:question1) do
    create(
      :questionnaire_question,
      question_type: "multiple-choice",
      question_identifier: question1_ident,
      question_text: "Question 1?",
      metadata: {
        "multiple-choice" => {
          "multiple" => true,
          "choices" => [
            {"label" => "Label 1.1", "value" => selection1, "selected" => false, "position" => 0},
            {"label" => "Label 1.2", "value" => "Value 1.2", "selected" => false, "position" => 0}
          ]
        }
      }
    )
  end
  let(:question2_ident) { "ident_2" }
  let(:selection2) { "Value 2.2" }
  let(:question2) do
    create(
      :questionnaire_question,
      question_type: "multiple-choice",
      question_identifier: question2_ident,
      question_text: "Question 2?",
      metadata: {
        "multiple-choice" => {
          "multiple" => true,
          "choices" => [
            {"label" => "Label 2.1", "value" => "Value 2.1", "selected" => false, "position" => 0},
            {"label" => "Label 2.2", "value" => selection2, "selected" => false, "position" => 0}
          ]
        }
      }
    )
  end
  let(:category) { create(:category, ident: "category_ident_1") }
  let(:questionnaire) do
    create(
      :questionnaire,
      category: category,
      questions: [question1, question2]
    )
  end
  let(:automation) { create(:offer_automation, questionnaire: questionnaire) }
  let(:plan1) { create(:plan, ident: "one", category: category) }
  let(:plan2) { create(:plan, ident: "two", category: category) }
  let(:plan3) { create(:plan, ident: "three", category: category) }

  describe "when unauthenticated" do
    it "should reject the access to get the rules" do
      json_admin_get_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules"
      expect(response.status).to eq(401)
    end

    it "should reject the access to post new rules" do
      json_admin_post_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules", {}
      expect(response.status).to eq(401)
    end
  end

  describe "when authenticated" do
    let(:plan1) { create(:plan, category: category, ident: "one") }
    let(:plan2) { create(:plan, category: category, ident: "two") }
    let(:plan3) { create(:plan, category: category, ident: "three") }
    let(:valid_rule) do
      create(
        :offer_rule,
        offer_automation: automation,
        category: category,
        name: "rule to be activated",
        answer_values: {
          question1_ident => selection1,
          question2_ident => selection2
        },
        plan_idents: [
          plan1.ident,
          plan2.ident,
          plan3.ident
        ],
        state: "inactive"
      )
    end

    before do
      login_as(admin, scope: :admin)
    end

    it "should get all offer rules for an automation ordered by name" do
      json_admin_get_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules"

      expect(response.status).to eq(200)
      expect(json_response.offer_rules).to eq([])

      rule1 = create(:offer_rule, offer_automation: automation, category: category, name: "Rule A")
      rule2 = create(
        :offer_rule,
        offer_automation: automation,
        category: category,
        name: "Rule B",
        answer_values: {
          question1_ident => selection1,
          question2_ident => selection2
        }
      )
      plans = [plan1, plan2, plan3]

      plan_option_types = {
        plan1.ident => "top_cover",
        plan2.ident => "top_price",
        plan3.ident => "top_cover_and_price"
      }

      rule2.update!(plan_idents: plans.map(&:ident), plan_option_types: plan_option_types)

      offer_rule_plans = plans.map do |plan|
        {
          "id" => nil,
          "ident" => plan.ident,
          "name" => plan.name,
          "company_name" => plan.company_name,
          "subcompany_id" => nil
        }
      end


      json_admin_get_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules"

      expect(response.status).to eq(200)
      expect(json_response.offer_rules).to eq(
        [
          {
            "id" => rule1.id.to_s,
            "name" => rule1.name,
            "state" => rule1.state,
            "offer_automation_id" => automation.id,
            "answer_values" => rule1.answer_values,
            "plan_idents" => [nil, nil, nil],
            "activated" => false,
            "plans" => [],
            "plan_option_types" => {}
          },
          {
            "id" => rule2.id.to_s,
            "name" => rule2.name,
            "state" => rule2.state,
            "offer_automation_id" => automation.id,
            "answer_values" => rule2.answer_values,
            "plan_idents" => rule2.plan_idents,
            "activated" => false,
            "plans" => offer_rule_plans,
            "plan_option_types" => plan_option_types
          }
        ]
      )
    end

    it "should post an offer rule" do
      answer_values = {
        question1_ident => selection1,
        question2_ident => selection2
      }
      plan_idents = [nil, nil, nil]
      payload = {
        name: "Name of the rule",
        state: "inactive",
        offer_automation_id: automation.id,
        answer_values: answer_values,
        plan_idents: plan_idents
      }

      json_admin_post_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules", payload

      # initial save works:
      expect(response.status).to eq(201)
      automation.reload
      rule = automation.offer_rules.find { |rule| rule.name == payload[:name] }
      expect(rule).to be_present
      expect(rule.answer_values).to eq(answer_values)
      expect(rule.plan_idents).to eq(plan_idents)

      # change the name:
      changed_name = "changed name"
      changed_payload = payload.merge(name: changed_name, id: rule.id)
      json_admin_post_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules", changed_payload

      expect(response.status).to eq(201)
      rule.reload
      expect(rule.name).to eq(changed_name)

      # change the plan idents:
      plan_idents[1] = plan2.ident
      json_admin_post_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules", changed_payload

      expect(response.status).to eq(201)
      rule.reload
      expect(rule.plan_idents).to eq(plan_idents)

      # fill the plan idents:
      plan_idents[0] = plan1.ident
      plan_idents[2] = plan3.ident
      json_admin_post_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules", changed_payload

      expect(response.status).to eq(201)
      rule.reload
      expect(rule.plan_idents).to eq(plan_idents)

      # fill the plan option types:
      plan_idents[0] = plan1.ident
      plan_idents[2] = plan3.ident

      changed_payload.merge!(
        plan_option_types: {
          plan_idents[0] => "top_cover",
          plan_idents[1] => "top_price",
          plan_idents[2] => "top_cover_and_price"
        }
      )
      json_admin_post_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules", changed_payload

      expect(response.status).to eq(201)
      rule.reload
      expect(rule.plan_option_types).to eq(changed_payload[:plan_option_types])

      # removes plan option type
      plan_idents[2] = nil
      changed_payload.merge!(
        plan_option_types: {
          plan_idents[0] => "top_cover",
          plan_idents[1] => "top_price"
        }
      )
      json_admin_post_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules", changed_payload

      expect(response.status).to eq(201)
      rule.reload
      expect(rule.plan_option_types).to eq(changed_payload[:plan_option_types])
    end

    it "should activate or deactivate an offer rule" do
      json_admin_patch_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules/#{valid_rule.id}/activate"
      expect_ok

      valid_rule.reload
      expect(valid_rule).to be_active

      json_admin_patch_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules/#{valid_rule.id}/deactivate"
      expect_ok

      valid_rule.reload
      expect(valid_rule).to be_inactive

      json_admin_patch_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules/not_known/activate"
      expect_not_found

      json_admin_patch_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules/not_known/deactivate"
      expect_not_found
    end

    it "should delete an offer rule" do
      json_admin_delete_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules/not_known"
      expect_ok

      json_admin_delete_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules/#{valid_rule.id}"
      expect_ok
      expect(OfferRule.where(id: valid_rule.id)).to be_empty
    end

    it "cannot delete an activated offer rule" do
      valid_rule.activate

      json_admin_delete_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules/#{valid_rule.id}"
      expect_method_not_allowed
    end

    context "Feature::OFFER_VIEW_LABELS on" do
      before { allow(Features).to receive(:active?).with(Features::OFFER_VIEW_LABELS).and_return(true) }

      it "returns possible plan option types of offer rule" do
        json_admin_get_v1 "/api/admin/offer_automations/#{automation.id}/plan_option_types"
        expect(json_response.plan_option_types).to eq OfferRule::PLAN_OPTION_TYPES
      end
    end

    context "Feature::OFFER_VIEW_LABELS off" do
      before { allow(Features).to receive(:active?).with(Features::OFFER_VIEW_LABELS).and_return(false) }

      it "returns possible plan option types of offer rule" do
        json_admin_get_v1 "/api/admin/offer_automations/#{automation.id}/plan_option_types"
        expect(json_response.plan_option_types).to eq []
      end
    end
  end

  describe "AssessLog" do
    let(:log_prefix_pattern) { %r{ACCESS_LOG.*api/} }
    let(:call) do
      json_admin_get_v1 "/api/admin/offer_automations/#{automation.id}/offer_rules"
    end

    before do
      login_as(admin, scope: :admin)
      allow(Rails.logger).to receive(:info).and_call_original
      allow(Settings).to receive_message_chain("security.access_log")
        .and_return(access_log_enabled)
    end

    context "when enabled" do
      let(:access_log_enabled) { true }

      it "saves a log entry" do
        expect(Rails.logger).to receive(:info)
          .with(log_prefix_pattern).once
        call
      end
    end

    context "when disabled" do
      let(:access_log_enabled) { false }

      it "doesn't save a log entry" do
        expect(Rails.logger).not_to receive(:info).with(log_prefix_pattern)
        call
      end
    end
  end
end
