# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::V4::Retirement::Process::Products::SubmitDetails, :integration, type: :api do
  let(:user) { create :user, mandate: mandate }
  let(:mandate) { create :mandate }

  before do
    create(
      :profile_datum,
      :yearly_gross_income,
      mandate: user.mandate,
      value: {text: "50000"}
    )
    create :retirement_income_tax, income_cents: 2_400_000, income_tax_percentage: 1_613
    create :retirement_elderly_deductible, deductible_max_amount_cents: 0, deductible_percentage: 0
    login_as user, scope: :user
  end

  describe "POST /api/retirement/process/dataonboarding/products/submit_details" do
    let(:subcompany) { create :subcompany }

    context "with private_rentenversicherung (COVERAGE_TYPE_1) category" do
      let(:category) { create :category, :private_rentenversicherung }

      let(:params) do
        {
          category_id: category.id,
          subcompany_id: subcompany.id,
          retirement_date: "01.02.2054",
          premium: 134.45,
          premium_payment_type: "monthly",
          surplus_retirement_income: 1_000,
          surplus_retirement_income_payment_type: "monthly"
        }
      end

      before do
        json_post_v4 "/api/retirement/process/dataonboarding/products/submit_details", params
      end

      it "creates a new product" do
        expect(response.status).to eq 201
        product = Product.last
        expect(product).to be_present
        expect(product.subcompany).to eq subcompany
        expect(product.retirement_product).to be_present
      end

      context "with minimal set of params" do
        let(:params) do
          {
            category_id: category.id,
            subcompany_id: subcompany.id,
            retirement_date: "01.02.2054",
            surplus_retirement_income: 1_000,
            surplus_retirement_income_payment_type: "monthly"
          }
        end

        it "creates a new product" do
          expect(response.status).to eq 201
          product = Product.last
          expect(product).to be_present
          expect(product).to be_customer_provided
        end
      end

      context "with invalid params" do
        context "with missing dependent params" do
          let(:params) do
            {
              category_id: category.id,
              subcompany_id: subcompany.id,
              retirement_date: "01.02.2054",
              surplus_retirement_income: "10"
            }
          end

          it "responds with an error" do
            expect(response.status).to eq 400
          end
        end
      end
    end

    context "with basis fonds (COVERAGE_TYPE_2) category" do
      let(:category) { create :category, :basis_fonds }

      let(:params) do
        {
          category_id: category.id,
          subcompany_id: subcompany.id,
          payment_type: "monthly",
          retirement_date: "01.01.2050",
          retirement_three_percent_growth: 100,
          retirement_three_percent_growth_payment_type: "monthly"
        }
      end

      before do
        json_post_v4 "/api/retirement/process/dataonboarding/products/submit_details", params
      end

      it "creates a new product" do
        expect(response.status).to eq 201
        product = Product.last
        expect(product).to be_present
        expect(product.subcompany).to eq subcompany
        expect(product.retirement_product).to be_present
        expect(product.retirement_product.retirement_three_percent_growth.to_f).to eq 100
      end

      context "with invalid params" do
        context "with missing dependent params" do
          let(:params) do
            {
              category_id: category.id,
              subcompany_id: subcompany.id,
              retirement_date: "01.02.2054",
              surplus_retirement_income: "10"
            }
          end

          it "responds with an error" do
            expect(response.status).to eq 400
          end
        end
      end
    end

    context "with pensionsfonds category" do
      let(:category) { create :category, :pensionsfonds }

      let(:params) do
        {
          category_id: category.id,
          subcompany_id: subcompany.id,
          retirement_date: "01.02.2054",
          premium: 134.45,
          premium_payment_type: "monthly",
          retirement_three_percent_growth: 33,
          retirement_three_percent_growth_payment_type: "monthly",
          guaranteed_capital: 150_000,
          retirement_factor: 35.70,
          retirement_factor_payment_type: "monthly",
          fund_capital_three_percent_growth: 84_214
        }
      end

      before do
        json_post_v4 "/api/retirement/process/dataonboarding/products/submit_details", params
      end

      it "creates a new product" do
        expect(response.status).to eq 201
        product = Product.last
        expect(product).to be_present
        expect(product.subcompany).to eq subcompany
        expect(product.retirement_product).to be_present
        expect(product.retirement_product.surplus_retirement_income_payment_type).to eq "monthly"
        expect(product.retirement_product.surplus_retirement_income.to_f).to eq 33
      end

      context "with minimal set of params" do
        let(:params) do
          {
            category_id: category.id,
            subcompany_id: subcompany.id,
            retirement_three_percent_growth: 33,
            retirement_three_percent_growth_payment_type: "monthly"
          }
        end

        it "creates a new product" do
          expect(response.status).to eq 201
          product = Product.last
          expect(product).to be_present
          expect(product).to be_customer_provided
        end
      end

      context "with invalid params" do
        context "with missing category specific required params" do
          context "with missing dependent params" do
            let(:params) do
              {
                category_id: category.id,
                subcompany_id: subcompany.id,
                retirement_three_percent_growth: nil,
                retirement_three_percent_growth_payment_type: nil
              }
            end

            it "responds with an error" do
              expect(response.status).to eq 400
            end
          end
        end

        context "with missing dependent params" do
          let(:params) do
            {
              category_id: category.id,
              subcompany_id: subcompany.id,
              retirement_three_percent_growth: 33,
              retirement_three_percent_growth_payment_type: "monthly",
              premium: 304.23,
              premium_payment_type: nil
            }
          end

          it "responds with an error" do
            expect(response.status).to eq 400
          end
        end
      end
    end

    context "with kapitallebensversicherung (COVERAGE_TYPE_3) category" do
      let(:category) { create :category, :kapitallebensversicherung }

      let(:params) do
        {
          category_id: category.id,
          subcompany_id: subcompany.id,
          retirement_date: "01.02.2054",
          premium: 134.45,
          premium_payment_type: "monthly",
          possible_capital_including_surplus: 9_000
        }
      end

      before do
        json_post_v4 "/api/retirement/process/dataonboarding/products/submit_details", params
      end

      it "creates a new product" do
        expect(response.status).to eq 201
        product = Product.last
        expect(product).to be_present
        expect(product.subcompany).to eq subcompany
        expect(product.retirement_product).to be_present
        expect(product.retirement_product.possible_capital_including_surplus.to_f).not_to be_zero
      end

      context "with minimal set of params" do
        let(:params) do
          {
            category_id: category.id,
            subcompany_id: subcompany.id,
            retirement_date: "01.02.2054",
            possible_capital_including_surplus: 9_000
          }
        end

        it "creates a new product" do
          expect(response.status).to eq 201
          product = Product.last
          expect(product).to be_present
          expect(product).to be_customer_provided
        end
      end

      context "with invalid params" do
        let(:params) do
          {
            category_id: category.id,
            subcompany_id: subcompany.id,
            premium: 134.45,
            premium_payment_type: "monthly"
          }
        end

        it "responds with an error" do
          expect(response.status).to eq 400
        end
      end
    end

    context "with direktzusage category" do
      let(:category) { create :category, :direktzusage }

      let(:params) do
        {
          category_id: category.id,
          subcompany_id: subcompany.id,
          retirement_date: "01.02.2054",
          premium: 134.45,
          premium_payment_type: "monthly",
          possible_capital_including_surplus: 9_000
        }
      end

      before do
        json_post_v4 "/api/retirement/process/dataonboarding/products/submit_details", params
      end

      it "creates a new product" do
        expect(response.status).to eq 201
        product = Product.last
        expect(product).to be_present
        expect(product.subcompany).to eq subcompany
        expect(product.retirement_product).to be_present
        expect(product.retirement_product.pension_capital_three_percent.to_f).to eq 9_000
      end

      context "with minimal set of params" do
        let(:params) do
          {
            category_id: category.id,
            subcompany_id: subcompany.id,
            retirement_date: "01.02.2054",
            possible_capital_including_surplus: 9_000
          }
        end

        it "creates a new product" do
          expect(response.status).to eq 201
          product = Product.last
          expect(product).to be_present
          expect(product).to be_customer_provided
        end
      end

      context "with invalid params" do
        let(:params) do
          {
            category_id: category.id,
            subcompany_id: subcompany.id,
            premium: 134.45,
            premium_payment_type: "monthly"
          }
        end

        it "responds with an error" do
          expect(response.status).to eq 400
        end
      end
    end
  end

  describe "PATCH /api/retirement/process/dataonboarding/products/submit_details/:id" do
    let(:subcompany) { create :subcompany }

    context "with private_rentenversicherung (COVERAGE_TYPE_1) category" do
      let(:category) { create :category, :private_rentenversicherung }
      let(:product) do
        create :product, mandate: mandate, category: category, subcompany: subcompany
      end

      let(:params) do
        {
          category_id: category.id,
          subcompany_id: subcompany.id,
          retirement_date: "01.02.2054",
          premium: 134.45,
          premium_payment_type: "monthly",
          guaranteed_pension_continueed_payment: 10_000,
          guaranteed_pension_continueed_payment_payment_type: "monthly",
          surplus_retirement_income: 1_000,
          surplus_retirement_income_payment_type: "monthly"
        }
      end

      before do
        json_patch_v4 "/api/retirement/process/dataonboarding/products/submit_details/#{product.id}", params
      end

      it "updates the product" do
        expect(response.status).to eq 200
        expect(product.reload).to be_present
        expect(product.retirement_product).to be_present
        expect(product.premium_period).to eq "month"
        expect(product.premium_price.to_f).to eq 134.45
        expect(product.retirement_product.guaranteed_pension_continueed_payment.to_i).to eq 10_000
      end

      context "with invalid params" do
        let(:params) do
          {
            category_id: category.id,
            subcompany_id: subcompany.id,
            retirement_date: "01.02.2054",
            guaranteed_pension_continueed_payment_payment_type: "monthly",
            surplus_retirement_income: "10"
          }
        end

        it "responds with an error" do
          expect(response.status).to eq 400
        end
      end
    end

    context "with pensionsfonds category" do
      let(:category) { create :category, :pensionsfonds }

      let(:product) { create :product, mandate: mandate, category: category, subcompany: subcompany }

      let(:params) do
        {
          retirement_date: "01.02.2054",
          premium: 134.45,
          premium_payment_type: "monthly",
          retirement_three_percent_growth: 33,
          retirement_three_percent_growth_payment_type: "monthly",
          guaranteed_capital: 150_000,
          retirement_factor: 35.70,
          retirement_factor_payment_type: "monthly",
          fund_capital_three_percent_growth: 84_214
        }
      end

      before do
        json_patch_v4 "/api/retirement/process/dataonboarding/products/submit_details/#{product.id}", params
      end

      it "updates the product" do
        expect(response.status).to eq 200
        expect(product.reload).to be_present
        expect(product.retirement_product).to be_present
        expect(product.premium_period).to eq "month"
        expect(product.premium_price.to_f).to eq 134.45
        expect(product.retirement_product.surplus_retirement_income_payment_type).to eq "monthly"
        expect(product.retirement_product.surplus_retirement_income.to_f).to eq 33
      end

      context "with invalid params" do
        let(:params) do
          {
            retirement_three_percent_growth: 33,
            retirement_three_percent_growth_payment_type: "monthly",
            premium: 304.23,
            premium_payment_type: nil
          }
        end

        it "responds with an error" do
          expect(response.status).to eq 400
        end
      end
    end

    context "with kapitallebensversicherung (COVERAGE_TYPE_3) category" do
      let(:category) { create :category, :kapitallebensversicherung }
      let(:product)  { create :product, mandate: mandate, category: category, subcompany: subcompany }

      let(:params) do
        {
          category_id: category.id,
          subcompany_id: subcompany.id,
          retirement_date: "01.02.2054",
          premium: 130.45,
          premium_payment_type: "monthly",
          guaranteed_capital: 20_000,
          possible_capital_including_surplus: 8_000
        }
      end

      before do
        json_patch_v4 "/api/retirement/process/dataonboarding/products/submit_details/#{product.id}", params
      end

      it "updates the product" do
        expect(response.status).to eq 200
        expect(product.reload).to be_present
        expect(product.retirement_product).to be_present
        expect(product.premium_period).to eq "month"
        expect(product.premium_price.to_f).to eq 130.45
        expect(product.retirement_product.retirement_date).to eq Date.new(2054, 2, 1)
      end

      context "with invalid params" do
        let(:params) do
          {
            category_id: category.id,
            subcompany_id: subcompany.id,
            retirement_date: "01.02.2054",
            premium: 134.45,
            premium_payment_type: "monthly"
          }
        end

        it "responds with an error" do
          expect(response.status).to eq 400
        end
      end
    end

    context "with direktzusage (COVERAGE_TYPE_3) category" do
      let(:category) { create :category, :direktzusage }
      let(:product)  { create :product, mandate: mandate, category: category, subcompany: subcompany }

      let(:params) do
        {
          category_id: category.id,
          subcompany_id: subcompany.id,
          retirement_date: "01.02.2054",
          premium: 130.45,
          premium_payment_type: "monthly",
          guaranteed_capital: 20_000,
          possible_capital_including_surplus: 8_000
        }
      end

      before do
        json_patch_v4 "/api/retirement/process/dataonboarding/products/submit_details/#{product.id}", params
      end

      it "updates the product" do
        expect(response.status).to eq 200
        expect(product.reload).to be_present
        expect(product.retirement_product).to be_present
        expect(product.premium_period).to eq "month"
        expect(product.premium_price.to_f).to eq 130.45
        expect(product.retirement_product.retirement_date).to eq Date.new(2054, 2, 1)
        expect(product.retirement_product.pension_capital_three_percent.to_f).to eq 8_000
      end

      context "with invalid params" do
        let(:params) do
          {
            category_id: category.id,
            subcompany_id: subcompany.id,
            retirement_date: "01.02.2054",
            premium: 134.45,
            premium_payment_type: "monthly"
          }
        end

        it "responds with an error" do
          expect(response.status).to eq 400
        end
      end
    end
  end
end
