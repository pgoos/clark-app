# frozen_string_literal: true

require "rails_helper"

describe Robo::ReoccurringAdviceRepository, :integration do
  subject { described_class.new }

  describe "#all" do
    let(:end_date) { 4.months.from_now }
    let(:maturity) { {month: end_date.month, day: end_date.day} }
    let(:plan) { create(:plan, :shallow, subcompany: create(:subcompany), category: create(:category)) }
    let(:admin) { create(:admin) }
    let(:mandate) { create(:mandate, active_address: nil) }
    let(:sold_by) { "others" }
    let!(:contract_ending_products) do
      create_list(:product, 2,
                  :shallow,
                  sold_by: sold_by,
                  state: state,
                  contract_ended_at: end_date,
                  annual_maturity: nil,
                  plan: plan,
                  category: category)
    end
    let!(:annual_maturity_products) do
      create_list(:product, 2,
                  :shallow,
                  sold_by: sold_by,
                  state: state,
                  contract_ended_at: nil,
                  annual_maturity: maturity,
                  plan: plan,
                  category: category)
    end

    context "when product had reoccurring advice but was recently updated" do
      let(:category) { create(:category_phv) }
      let(:state) { :details_available }
      let(:recently_updated_products_with_reoccurring_advices) do
        create_list(:product, 2,
                    :shallow,
                    sold_by: sold_by,
                    state: state,
                    contract_ended_at: nil,
                    annual_maturity: nil,
                    plan: plan,
                    category: category)
      end
      let(:create_invalid_advice) do
        lambda do |product|
          create(:advice, :reoccurring_advice, valid: false, product: product, admin: admin, mandate: mandate)
        end
      end

      before do
        recently_updated_products_with_reoccurring_advices.each do |product|
          create_invalid_advice.(product)
        end
      end

      it do
        expect(subject.all).to match_array recently_updated_products_with_reoccurring_advices
      end
    end

    context "when products have not received advice yet" do
      let(:category) { create(:category_phv) }
      let(:state) { :details_available }

      it do
        expect(subject.all).to match_array []
      end
    end

    context "when products have received advice" do
      let(:create_advice) do
        lambda do |product|
          create(:advice,
                 :created_by_robo_advisor,
                 created_at: 9.months.ago,
                 product: product,
                 admin: admin,
                 mandate: mandate)
        end
      end

      before do
        [*contract_ending_products, *annual_maturity_products].each do |product|
          create_advice.(product)
        end
      end

      context "when category is supported" do
        let(:category) { create(:category_phv) }

        context "when active" do
          let(:state) { :details_available }

          it do
            expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
          end

          context "when advice have been sent in the last 6 months" do
            let(:create_advice) do
              lambda do |product|
                create(:advice,
                       :created_by_robo_advisor,
                       created_at: 5.months.ago,
                       product: product,
                       admin: admin,
                       mandate: mandate)
              end
            end

            it do
              expect(subject.all).to match_array []
            end
          end

          context "when specific product has received two advices" do
            before do
              create_advice.(contract_ending_products[0])
            end

            it do
              expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
            end
          end

          context "when contract_ended_date and annual_maturity" do
            let!(:annual_maturity_with_end_date_product) do
              create(:product,
                     :shallow,
                     state: state,
                     contract_ended_at: end_date,
                     annual_maturity: maturity,
                     plan: plan,
                     category: category)
            end

            before do
              create(
                :advice,
                :created_by_robo_advisor,
                product: annual_maturity_with_end_date_product,
                created_at: 2.years.ago,
                admin: admin
              )
            end

            it do
              expect(subject.all).to match_array(contract_ending_products +
                                                 annual_maturity_products +
                                                 [annual_maturity_with_end_date_product])
            end
          end

          context "when sold_by us" do
            let(:sold_by) { "us" }

            it do
              expect(subject.all.count).to be_zero
            end
          end

          context "when previous advised" do
            let!(:previously_advised_products) do
              create_list(:product, 2,
                          :shallow,
                          plan: plan,
                          state: state,
                          contract_ended_at: nil,
                          annual_maturity: nil,
                          category: category)
            end

            before do
              previously_advised_products.each do |product|
                create(:advice, :created_by_robo_advisor, product: product, created_at: 1.year.ago, mandate: mandate)
              end
            end

            it do
              expect(subject.all).to match_array(contract_ending_products +
                                                 annual_maturity_products +
                                                 previously_advised_products)
            end

            context "clark 2.0 product created" do
              let(:product_clark_2) do
                create(
                  :product,
                  :shallow,
                  category: category,
                  plan: plan,
                  contract_ended_at: nil,
                  annual_maturity: nil,
                  state: "customer_provided",
                  analysis_state: "details_complete",
                  advices: [create(:advice, :created_by_robo_advisor, created_at: 1.year.ago, mandate: mandate)]
                )
              end

              let(:product_clark_2_without_details) do
                create(
                  :product,
                  :shallow,
                  category: category,
                  plan: plan,
                  contract_ended_at: nil,
                  annual_maturity: nil,
                  state: "customer_provided",
                  analysis_state: Contracts::Entities::Contract::AnalysisState::DETAILS_MISSING
                )
              end

              let(:product_clark_2_under_analysis) do
                create(
                  :product,
                  :shallow,
                  category: category,
                  plan: plan,
                  contract_ended_at: nil,
                  annual_maturity: nil,
                  state: "customer_provided",
                  analysis_state: Contracts::Entities::Contract::AnalysisState::UNDER_ANALYSIS
                )
              end

              let(:product_clark_2_analysis_failed) do
                create(
                  :product,
                  :shallow,
                  category: category,
                  plan: plan,
                  contract_ended_at: nil,
                  annual_maturity: nil,
                  state: "customer_provided",
                  analysis_state: Contracts::Entities::Contract::AnalysisState::ANALYSIS_FAILED
                )
              end

              it "finds product with state customer_provided, analysis_state details_complete" do
                product_clark_2
                product_clark_2_without_details
                product_clark_2_under_analysis
                product_clark_2_analysis_failed

                expect(subject.all).to match_array(contract_ending_products +
                                              annual_maturity_products +
                                              previously_advised_products +
                                              Array.wrap(product_clark_2))
              end
            end
          end
        end

        context "when home insurance" do
          let(:category) { create(:category_home_insurance) }

          context "when active" do
            let(:state) { :details_available }

            it do
              expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
            end
          end
        end

        context "when disability insurance" do
          let(:category) { create(:bu_category) }

          context "when active" do
            let(:state) { :details_available }

            it do
              expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
            end
          end
        end

        context "when category not supported" do
          let(:category) { create(:pa_category) }

          context "when active" do
            let(:state) { :details_available }

            it do
              expect(subject.all.count).to be_zero
            end
          end
        end
      end

      context "when category is legal protection" do
        let(:category) { create(:category_legal) }

        context "when active" do
          let(:state) { :details_available }

          it do
            expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
          end
        end
      end

      context "when accident insurance" do
        let(:category) { create(:category_accident_insurace) }

        context "when active" do
          let(:state) { :details_available }

          it do
            expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
          end
        end
      end

      context "when car insurance" do
        let(:category) { create(:category_car_insurance) }

        context "when active" do
          let(:state) { :details_available }

          it do
            expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
          end
        end
      end

      context "when household" do
        let(:category) { create(:category_hr) }

        context "when active" do
          let(:state) { :details_available }

          it do
            expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
          end
        end
      end

      context "when dental" do
        let(:category) { create(:category_dental) }

        context "when active" do
          let(:state) { :details_available }

          it do
            expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
          end
        end
      end

      context "when travel health" do
        let(:category) { create(:category_travel_health) }

        context "when active" do
          let(:state) { :details_available }

          it do
            expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
          end
        end
      end

      context "when risk life" do
        let(:category) { create(:category_risk_life) }

        context "when active" do
          let(:state) { :details_available }

          it do
            expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
          end
        end
      end

      context "when private health" do
        let(:category) { create(:category_pkv, :advice_enabled) }

        context "when active" do
          let(:state) { :details_available }

          it do
            expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
          end
        end
      end

      context "when roadside assistance" do
        let(:category) { create(:category_roadside_assistance, :advice_enabled) }

        context "when active" do
          let(:state) { :details_available }

          it do
            expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
          end
        end
      end

      context "when riester" do
        let(:category) { create(:category_riester, :advice_enabled) }

        context "when active" do
          let(:state) { :details_available }

          it do
            expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
          end
        end
      end

      context "when retirement" do
        let(:category) { create(:category_retirement, :advice_enabled) }

        context "when active" do
          let(:state) { :details_available }

          it do
            expect(subject.all).to match_array(contract_ending_products + annual_maturity_products)
          end
        end
      end

      context "when inactive" do
        let(:category) { create(:category_phv) }
        let(:state) { :terminated }

        before do
          maturity = {month: Time.current.month, day: Time.current.day - 1}
          create(:product,
                 :shallow,
                 plan: plan,
                 state: state,
                 contract_ended_at: end_date + 1.month,
                 category: category)
          create(:product,
                 :shallow,
                 plan: plan,
                 state: state,
                 contract_ended_at: nil,
                 annual_maturity: maturity,
                 category: category)
        end

        it do
          expect(subject.all.count).to be_zero
        end
      end
    end
  end
end
