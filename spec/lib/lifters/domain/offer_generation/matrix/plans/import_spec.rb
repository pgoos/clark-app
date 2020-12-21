# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OfferGeneration::Matrix::Plans::Import, :integration do
  subject { described_class.new(path: "") }

  before do
    allow_any_instance_of(described_class).to(
      receive(:attach_assets).and_return(nil)
    )
  end

  describe "#call" do
    let(:plan_ident) { "plan1" }
    let(:category_ident) { "category1" }
    let(:company_ident) { "company1" }
    let(:subcompany_ident) { "subcompany1" }
    let(:vertical_ident) { "vertical1" }

    let(:data) do
      {
        companies: {company_ident => company_data},
        subcompanies: {subcompany_ident => subcompany_data},
        verticals: {vertical_ident => vertical_data},
        plans: {plan_ident => plan_data},
        offer_rules: offer_rules_data
      }
    end

    let(:vertical_data) do
      {
        ident: vertical_ident,
        name: "Vertical1",
        state: "active"
      }.stringify_keys
    end

    let(:company_data) do
      {
        name: "Company1",
        state: "active",
        ident: company_ident,
        country_code: "DE",
        info: company_info,
        logo: "some_dummy_url"
      }.stringify_keys
    end

    let(:company_info) do
      {
        info_phone: "+492026958780",
        damage_phone: "+492026958780"
      }.stringify_keys
    end

    let(:subcompany_data) do
      {
        name: "Subcompany1",
        ident: subcompany_ident,
        company_id: company_ident,
        vertical_id: vertical_ident
      }.stringify_keys
    end

    let(:plan_data) do
      {
        ident: plan_ident,
        name: "Plan1",
        state: "active",
        company_id: company_ident,
        subcompany_id: subcompany_ident,
        category_id: category_ident
      }.stringify_keys
    end

    let(:offer_rules_data) do
      {}
    end

    let(:expected_plan_attr) do
      slice = %w[ident name state]
      a_hash_including(
        plan_data.slice(*slice)
      )
    end

    let(:expected_company_attr) do
      slice = %w[name state ident country_code info]
      a_hash_including(
        company_data.slice(*slice)
      )
    end

    let(:expected_subcompany_attr) do
      slice = %w[name ident]
      a_hash_including(
        subcompany_data.slice(*slice)
      )
    end

    let(:expected_vertical_attr) do
      slice = %w[name ident state]
      a_hash_including(
        vertical_data.slice(*slice)
      )
    end

    before do
      allow(YAML).to receive(:load_file).and_return(data)
    end

    context "with correct data" do
      let!(:category) { create(:category, ident: category_ident) }
      let!(:vertical) { create(:vertical, ident: vertical_ident) }

      let!(:call) { subject.call }

      it "returns no errors" do
        expect(call).to eq({})
      end

      it "creates a plan" do
        expect(Plan.count).to eq(1)
        expect(Plan.first.attributes).to match(expected_plan_attr)
      end

      it "creates a company" do
        expect(Company.count).to eq(1)
        expect(Company.first.attributes).to match(expected_company_attr)
      end

      it "creates a subcompany" do
        expect(Subcompany.count).to eq(1)
        expect(Subcompany.first.attributes).to match(expected_subcompany_attr)
      end

      it "assigns company to plan" do
        plan = Plan.find_by(ident: plan_ident)
        expect(plan.company&.ident).to eq(company_ident)
      end

      it "assigns subcompany to company" do
        subcompany = Subcompany.find_by(ident: subcompany_ident)
        expect(subcompany.company&.ident).to eq(company_ident)
      end

      it "assigns subcompany to plan" do
        plan = Plan.find_by(ident: plan_ident)
        expect(plan.subcompany&.ident).to eq(subcompany_ident)
      end

      it "assigns category to plan" do
        plan = Plan.find_by(ident: plan_ident)
        expect(plan.category&.ident).to eq(category_ident)
      end
    end

    context "with provided logo url" do
      let!(:category) { create(:category, ident: category_ident) }
      let!(:vertical) { create(:vertical, ident: vertical_ident) }

      context "when no error happens" do
        it "assigns logo" do
          expect_any_instance_of(described_class).to receive(:attach_assets)
          expect(subject.call).to eq({})
        end
      end
    end

    context "when create_object raises an error" do
      let!(:category) { create(:category, ident: category_ident) }
      let!(:vertical) { create(:vertical, ident: vertical_ident) }

      before do
        allow_any_instance_of(described_class).to(
          receive(:create_object).and_raise(StandardError, "Wrong!")
        )
      end

      it "catches this error" do
        expect(subject.call).to eq(plan_ident => ["Wrong!"])
      end
    end

    context "when category doesn't exist" do
      let!(:vertical) { create(:vertical, ident: vertical_ident) }

      let!(:call) { subject.call }

      it "returns error" do
        expect(call).to eq(
          plan_ident => [
            "Category '#{category_ident}' doesn't exist"
          ]
        )
      end
    end

    context "when vertical doesn't exist" do
      let!(:category) { create(:category, ident: category_ident) }

      let!(:call) { subject.call }

      it "returns error" do
        expect(call).to eq(
          plan_ident => [
            "Vertical '#{vertical_ident}' doesn't exist"
          ]
        )
      end
    end

    context "when company exists" do
      let!(:vertical) { create(:vertical, ident: vertical_ident) }
      let!(:category) { create(:category, ident: category_ident) }
      let!(:company) { create(:company, ident: company_ident) }

      let!(:call) { subject.call }

      it "returns no errors" do
        expect(call).to eq({})
      end

      it "assigns existing company to subcompany" do
        subcompany = Subcompany.find_by(ident: subcompany_ident)
        expect(subcompany.company).to eq(company)
      end
    end

    context "when subcompany assigned to another company" do
      let!(:vertical) { create(:vertical, ident: vertical_ident) }
      let!(:category) { create(:category, ident: category_ident) }
      let!(:subcompany) do
        create(
          :subcompany,
          ident: subcompany_ident,
          verticals: [vertical]
        )
      end

      let!(:call) { subject.call }

      it "returns error" do
        expect(call).to eq(
          plan_ident => [
            "Subcompany '#{subcompany_ident}' assigned to the different company"
          ]
        )
      end
    end

    context "when plan exists" do
      let!(:vertical) { create(:vertical, ident: vertical_ident) }
      let!(:category) { create(:category, ident: category_ident) }
      let!(:plan) { create(:plan, ident: plan_ident) }
      let!(:call) { subject.call }

      it "returns error" do
        expect(call).to eq(
          plan_ident => [
            "Plan '#{plan_ident}' exists"
          ]
        )
      end
    end

    describe "assign plans to offer_rules" do
      let!(:vertical) { create(:vertical, ident: vertical_ident) }
      let!(:category) { create(:category, ident: category_ident) }

      let(:offer_rule_name) { "rule1" }

      let(:plan_idents) { [] }

      let(:offer_rules_data) do
        {
          offer_rule_name => plan_idents
        }
      end

      context "when rule exists" do
        let!(:plan2) do
          create(
            :plan,
            category: category,
            state: "active"
          )
        end

        let!(:plan3) do
          create(
            :plan,
            category: category,
            state: "active"
          )
        end

        let!(:offer_rule) do
          create(
            :offer_rule,
            name: offer_rule_name,
            category: category,
            plan_idents: [nil, nil, nil]
          )
        end

        context "when plans are correct for offer rule" do
          let(:plan_idents) { [plan_ident, plan2.ident, plan3.ident] }

          let!(:call) { subject.call }

          it "returns no errors" do
            expect(call).to eq({})
          end

          it "assigns plans idents to the offer rule" do
            expect(offer_rule.reload.plan_idents).to eq(plan_idents)
          end
        end

        context "when plans are incorrect for offer rule" do
          let!(:call) { subject.call }

          it "returns error" do
            expect(call).to match(
              offer_rule_name => [
                a_string_starting_with("Rule '#{offer_rule_name}':")
              ]
            )
          end
        end
      end

      context "when rule doesn't exist" do
        let!(:call) { subject.call }

        it "returns error" do
          expect(call).to match(
            offer_rule_name => [
              "Offer rule '#{offer_rule_name}' doesn't exist"
            ]
          )
        end
      end
    end
  end
end
