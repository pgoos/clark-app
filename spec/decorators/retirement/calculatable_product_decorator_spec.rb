# frozen_string_literal: true

require "rails_helper"

describe Retirement::CalculatableProductDecorator, type: :decorator do
  subject { described_class.new retirement_product }

  let(:retirement_product) { build :retirement_product, :details_available, :shallow }
  let(:surplus) { double :surplus, to_i: 20_000 }

  let(:situation) do
    instance_double(
      Domain::Situations::RetirementSituation,
      birthdate: Date.new(1990, 1, 1),
      health_care_insurance: :state,
      has_kids?: true,
      gender: "male",
      retirement_age: 65,
      years_till_retirement: 40
    )
  end

  before do
    subject.situation = situation
  end

  describe "#gross_income" do
    context "when product is in state details_available" do
      before do
        allow(Domain::Retirement::Estimations::Products::Surplus).to receive(:new) \
          .with(subject).and_return surplus
      end

      it "returns calculated surplus" do
        expect(subject.gross_income).to be_kind_of Money
        expect(subject.gross_income.to_f).to eq 200.0
      end
    end

    context "when product is in state created" do
      before do
        allow(Domain::Retirement::Estimations::Products::Surplus).to receive(:new) \
          .with(subject).and_return surplus
      end

      context "with document forecast" do
        let(:retirement_product) do
          build :retirement_product, :shallow, :created, :document_forecast
        end

        it "returns zero" do
          expect(subject.gross_income).to be_kind_of Money
          expect(subject.gross_income.to_f).to eq 0.0
        end
      end

      context "with initial forecast" do
        let(:retirement_product) do
          build :retirement_product, :shallow, :created, :initial_forecast
        end

        it "calculates value" do
          expect(subject.gross_income.to_f).to eq 200.0
        end
      end

      context "with customer forecast" do
        let(:retirement_product) do
          build :retirement_product, :shallow, :created, :customer_forecast
        end

        it "calculates value" do
          expect(subject.gross_income.to_f).to eq 200.0
        end
      end
    end

    context "not implemented 'riester_fonds_non_insurance'" do
      before { allow(retirement_product).to receive(:category).and_return :riester_fonds_non_insurance }

      it "returns Money object with zero value" do
        expect(subject.gross_income).to be_kind_of Money
        expect(subject.gross_income.to_f).to eq 0.0
      end

      it "triggers Sentry notification" do
        expect(Raven).to receive(:capture_exception).with(NotImplementedError)

        subject.gross_income
      end
    end
  end

  describe "#taxable_income_pre_deductibles" do
    before do
      allow(Domain::Retirement::TaxationTypes).to \
        receive(:for_product).with(subject).and_return taxation_type

      allow(Domain::Retirement::Estimations::Products::Surplus).to receive(:new) \
        .with(subject).and_return surplus
    end

    context "when taxation type is type1" do
      let(:taxation_type) { :type1 }

      it "returns gross income" do
        expect(subject.taxable_income_pre_deductibles.to_f).to eq 200.0
      end
    end

    context "when taxation type is type2" do
      let(:taxation_type) { :type2 }

      it "returns gross income" do
        expect(subject.taxable_income_pre_deductibles.to_f).to eq 200.0
      end
    end

    context "when taxation type is type3" do
      let(:taxation_type) { :type3 }

      it "returns gross income multiplied by profit share percent" do
        expect(subject.taxable_income_pre_deductibles.to_f).to eq 36.0
      end
    end

    context "when taxation type is base" do
      let(:taxation_type) { :base }

      it "returns gross income" do
        expect(subject.taxable_income_pre_deductibles.to_f).to eq 200.0
      end
    end

    context "when taxation type is riester" do
      let(:taxation_type) { :riester }

      it "returns gross income" do
        expect(subject.taxable_income_pre_deductibles.to_f).to eq 200.0
      end
    end
  end

  describe "#contribution" do
    context "with state category" do
      let(:product) { build :product, :retirement_state_category }
      let(:retirement_product) { build :retirement_product, :state, product: product }

      it { expect(subject.contribution).to eq 9.3 }
    end

    context "with other category" do
      let(:product) { build :product, :retirement_personal_category }
      let(:retirement_product) { build :retirement_product, product: product }

      it { expect(subject.contribution).to eq 0.0 }
    end
  end

  describe "#taxable_income_post_deductibles" do
    let(:product) { build :product, :retirement_state_category }
    let(:surplus) { double :surplus, to_i: 20_000 }

    let(:retirement_product) do
      build :retirement_product, :state, :details_available, product: product
    end

    before do
      allow(Domain::Retirement::Estimations::Products::Surplus).to receive(:new) \
        .with(subject).and_return surplus
      allow(Domain::Retirement::Estimations::SocialSecurity).to receive(:call) \
        .with(
          gross_income: 20_000,
          category_ident: "84a5fba0",
          health_care_insurance: :state,
          has_kids: true,
          gender: "male"
        ).and_return 3_000
      allow(Domain::Retirement::Tax::TaxableIncomePostDeductibles).to receive(:call) \
        .and_return 15_000
    end

    it "returns calculated taxable income" do
      expect(Domain::Retirement::Tax::TaxableIncomePostDeductibles).to receive(:call) \
        .with(20_000, 3_000, 5, 2_000)

      expect(subject.taxable_income_post_deductibles(Money.new(2_000), 5)).to be_kind_of Money
      expect(subject.taxable_income_post_deductibles(Money.new(2_000), 5).to_f).to eq 150.0
    end
  end

  describe "#net_income" do
    let(:product) { build :product, :retirement_state_category }
    let(:surplus) { double :surplus, to_i: 20_000 }

    let(:retirement_product) do
      build :retirement_product, :state, :details_available, product: product
    end

    before do
      allow(Domain::Retirement::Estimations::Products::Surplus).to receive(:new) \
        .with(subject).and_return surplus
      allow(Domain::Retirement::Estimations::SocialSecurity).to receive(:call) \
        .with(
          gross_income: 20_000,
          category_ident: "84a5fba0",
          health_care_insurance: :state,
          has_kids: true,
          gender: "male"
        ).and_return 3_000
      allow(Domain::Retirement::Tax::TaxableIncomePostDeductibles).to receive(:call) \
        .with(20_000, 3_000, 5, 2_000).and_return 15_000
      allow(Domain::Retirement::Estimations::NetIncome).to receive(:call) \
        .and_return 10_000
    end

    it "returns calculated surplus" do
      expect(Domain::Retirement::Estimations::NetIncome).to receive(:call) \
        .with(
          gross_product_income: 20_000,
          social_security: 3_000,
          taxable_income_post_deductibles: 15_000,
          total_taxable_income_post_deductibles: 30_000
        )

      expect(subject.net_income(Money.new(2_000), Money.new(30_000), 5)).to be_kind_of Money
      expect(subject.net_income(Money.new(2_000), Money.new(30_000), 5).to_f).to eq 100.0
    end
  end

  describe "#net_income_todays_values" do
    let(:product) { build :product, :retirement_state_category }
    let(:surplus) { double :surplus, to_i: 20_000 }

    let(:retirement_product) do
      build :retirement_product, :state, :details_available, product: product
    end

    context "when DE" do
      before do
        allow(Internationalization).to receive(:locale).and_return(:de)
        allow(Domain::Retirement::Estimations::Products::Surplus).to receive(:new) \
          .with(subject).and_return surplus
        allow(Domain::Retirement::Estimations::SocialSecurity).to receive(:call) \
          .with(
            gross_income: 20_000,
            category_ident: "84a5fba0",
            health_care_insurance: :state,
            has_kids: true,
            gender: "male"
          ).and_return 3_000
        allow(Domain::Retirement::Tax::TaxableIncomePostDeductibles).to receive(:call) \
          .with(20_000, 3_000, 5, 2_000).and_return 15_000
        allow(Domain::Retirement::Estimations::NetIncome).to receive(:call) \
          .and_return 10_000
        allow(Domain::Retirement::Formulas::TodaysValues).to receive(:call) \
          .and_return 8_000
      end

      it "returns calculated surplus" do
        expect(Domain::Retirement::Estimations::NetIncome).to receive(:call) \
          .with(
            gross_product_income: 20_000,
            social_security: 3_000,
            taxable_income_post_deductibles: 15_000,
            total_taxable_income_post_deductibles: 30_000
          )
        expect(Domain::Retirement::Formulas::TodaysValues).to receive(:call).with(Money.from_amount(100), 40)

        expect(subject.net_income_todays_values(Money.new(2_000), Money.new(30_000), 5)).to be_kind_of Money
        expect(subject.net_income_todays_values(Money.new(2_000), Money.new(30_000), 5).to_f).to eq 80.0
      end
    end

    context "when AT" do
      before do
        allow(Internationalization).to receive(:locale).and_return(:at)
      end

      context "when product has state category" do
        before { allow(retirement_product).to receive(:category).and_return "gesetzliche_alterspension" }

        context "when calculation result is not present" do
          it "returns 0" do
            net_income_todays_values = subject.net_income_todays_values(Money.new(2_000), Money.new(30_000), 5)
            expect(net_income_todays_values).to be_kind_of Money
            expect(net_income_todays_values.to_f).to eq 0.0
          end
        end

        context "when calculation result is not ready" do
          let(:calculation_result) { create(:retirement_calculation_result, state: :calculation_running) }
          let!(:cockpit) do
            create(:retirement_cockpit, mandate: retirement_product.mandate,
                  retirement_calculation_result: calculation_result)
          end

          it "returns 0" do
            net_income_todays_values = subject.net_income_todays_values(Money.new(2_000), Money.new(30_000), 5)
            expect(net_income_todays_values).to be_kind_of Money
            expect(net_income_todays_values.to_f).to eq 0.0
          end
        end

        context "when calculation result is succesful" do
          let(:calculation_result) do
            create(:retirement_calculation_result, desired_income_cents: 100_000, state: :calculation_successful)
          end
          let!(:cockpit) do
            create(:retirement_cockpit, mandate: retirement_product.mandate,
                  retirement_calculation_result: calculation_result)
          end

          it "returns desired_income_cents from Varias result" do
            net_income_todays_values = subject.net_income_todays_values(Money.new(2_000), Money.new(30_000), 5)
            expect(net_income_todays_values).to be_kind_of Money
            expect(net_income_todays_values.to_f).to eq 1000.0
          end
        end
      end

      context "when product does not have state category" do
        let(:retirement_product) do
          build :retirement_product, :details_available, :shallow, surplus_retirement_income: 200
        end

        it "returns surplus_retirement_income" do
          net_income_todays_values = subject.net_income_todays_values(Money.new(2_000), Money.new(30_000), 5)
          expect(net_income_todays_values).to be_kind_of Money
          expect(net_income_todays_values.to_f).to eq 200.0
        end
      end
    end
  end
end
