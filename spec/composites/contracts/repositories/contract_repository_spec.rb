# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/repositories/contract_repository"
require "composites/contracts/params"

RSpec.describe Contracts::Repositories::ContractRepository, :integration do
  subject { described_class.new }

  describe "#find_contract_details" do
    let(:contract) { create(:contract, :with_customer_uploaded_document, :details_missing) }
    let(:product) { Product.find_by(id: contract.id) }
    let(:category) { product.category }
    let(:currency) { Currency::EURO }
    let(:gkv_rate) { Domain::Products::Gkv::CostCalculator.call(product) }

    context "shared contract feature" do
      before do
        allow(Features).to receive(:active?).and_call_original
      end

      context "when feature flag is ON" do
        before do
          allow(Features).to receive(:active?).with(Features::SHARED_CONTRACTS).and_return(true)
        end

        it "returns the contract" do
          expect(Product.count).to be_zero

          product = create(:product, :under_management, :shared_contract)
          expect(Product.count).to be(1)

          contract = subject.find_contract_details(id: product.id)
          expect(contract).not_to be_nil

          %i[
            id
            state
            category_ident
            plan_name
            analysis_state
            company_name
            coverages
            renewal_period
          ].each do |attr|
            expect(contract[attr]).to eq(product.send(attr))
          end
        end
      end

      context "when feature flag is OFF" do
        before do
          allow(Features).to receive(:active?).with(Features::SHARED_CONTRACTS).and_return(false)
        end

        it "returns the contract" do
          expect(Product.ignoring_insurance_holder_value.count).to be_zero

          product = create(:product, :under_management, :shared_contract)
          expect(Product.ignoring_insurance_holder_value.count).to be(1)

          contract = subject.find_contract_details(id: product.id)
          expect(contract).to be_nil
        end
      end
    end

    context "when contract exists" do
      it "returns entity with aggregated data with documents" do
        result = subject.find_contract_details(id: contract.id)
        expect(result).to be_kind_of Hash
        expect(result[:id]).to eq contract.id
        expect(result[:state]).to eq contract.state
        expect(result[:category_ident]).to eq contract.category_ident
        expect(result[:category_name]).to eq contract.category_name
        expect(result[:plan_name]).to eq contract.plan_name
        expect(result[:customer_id]).to eq contract.customer_id
        expect(result[:analysis_state]).to eq contract.analysis_state
        expect(result[:premium_price]).to eq contract.premium_price.symbolize_keys
        expect(result[:renewal_period]).to eq contract.renewal_period

        premium_price = product.premium_price
        expect(result[:id]).to eq product.id
        expect(result[:state]).to eq product.state
        expect(result[:company_name]).to eq(product.company_name)
        expect(result[:company_logo]).to eq(product.company.logo_url)
        expect(result[:rating_score]).to eq(product.subcompany.rating_score)
        expect(result[:rating_text]).to eq(product.subcompany.rating_text_de)
        expect(result[:category_ident]).to eq product.category.ident
        expect(result[:category_name]).to eq product.category.name
        expect(result[:category_tips]).to eq(category.tips)
        expect(result[:plan_name]).to eq product.plan_name
        expect(result[:customer_id]).to eq product.mandate_id
        expect(result[:analysis_state]).to eq product.analysis_state
        expect(result[:premium_price]).to eq(value: premium_price.cents, currency: currency, unit: "Money")
        expect(result[:renewal_period]).to eq product.renewal_period
        expect(result[:coverages]).to eq product.coverages

        # expect documents to be there
        document = result[:documents].first
        expect(result[:documents].count).to eq(1)
        expect(document.id).to eq(product.documents.first.id)

        # verify coverage feature
        coverage_feature = category.coverage_features.first
        expect(result[:coverage_features].first).to include(
          identifier: coverage_feature.identifier,
          value_type: coverage_feature.value_type,
          name: coverage_feature.name
        )
      end
    end

    context "when contract does not exist" do
      it "returns nil" do
        expect(subject.find_contract_details(id: 999)).to eq(nil)
      end
    end

    context "when contract is GKV" do
      before do
        allow_any_instance_of(Product).to receive(:from_gkv?).and_return(true)
        allow_any_instance_of(Product).to receive(:based_on_salary?).and_return(true)
      end

      it "returns contract with gkv rate" do
        result = subject.find_contract_details(id: contract.id)

        expect(result[:premium_price]).to eq(
          value: gkv_rate,
          currency: currency,
          unit: "%"
        )
      end
    end
  end

  describe "#add_contracts!" do
    let(:vertical) { create(:vertical) }
    let(:customer) { create(:mandate) }
    let(:category) { create(:category, vertical: vertical) }
    let(:company) { create(:company) }
    let!(:subcompany1) { create(:subcompany, company: company, verticals: [vertical], principal: true) }
    let!(:subcompany2) { create(:subcompany, company: company, verticals: [vertical]) }

    context "with valid params" do
      let(:contract_params) do
        [
          Contracts::Params::NewContract.new(
            category_ident: category.ident,
            company_ident: company.ident,
            shared: false
          ),
          Contracts::Params::NewContract.new(
            category_ident: category.ident,
            company_ident: company.ident,
            shared: true
          )
        ]
      end

      it "creates and returns array of contracts" do
        result = subject.add_contracts!(customer.id, contract_params)
        expect(result).to be_kind_of Array

        result.each do |contract|
          product = Product.unscoped.find(contract.id)

          expect(contract).to be_kind_of Contracts::Entities::Contract
          expect(contract.state).to eq(product.state)
          expect(contract.analysis_state).to eq(product.analysis_state)
          expect(contract.insurance_holder).to eq(product.insurance_holder)
          expect(contract.category_ident).to eq(category.ident)
          expect(contract.plan_name).to eq("#{category.name} #{company.name}")
          expect(product.plan.category_id).to eq(category.id)
          expect(product.plan.company_id).to eq(company.id)
          expect(product.plan.subcompany_id).to eq(subcompany1.id)
        end
      end

      context "when there is only one subcompany for given category" do
        let!(:subcompany1) { nil }
        let!(:subcompany2) { create(:subcompany, company: company, verticals: [vertical]) }

        it "sets subcompany regardless principal flag" do
          result = subject.add_contracts!(customer.id, contract_params)
          product = Product.find(result.first.id)
          expect(product.plan.category_id).to eq(category.id)
          expect(product.plan.company_id).to eq(company.id)
          expect(product.plan.subcompany_id).to eq(subcompany2.id)
        end
      end

      context "when there is no subcompany for given category" do
        let!(:subcompany1) { nil }
        let!(:subcompany2) { nil }

        it "raises not found error" do
          expect { subject.add_contracts!(customer.id, contract_params) }
            .to raise_error(Utils::Repository::Errors::NotFoundError)
        end
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        [
          Contracts::Params::NewContract.new(
            category_ident: "FOO",
            company_ident: "BAR",
            shared: false
          )
        ]
      end

      it "raises error" do
        expect { subject.add_contracts!(customer.id, invalid_params) }.to raise_error described_class::Error
      end
    end
  end

  describe "#under_analysis" do
    before do
      create(:contract, :with_customer_uploaded_document, :details_complete)
    end

    it "returns contract" do
      contract = create(:contract, :with_customer_uploaded_document, :under_analysis)

      result = subject.under_analysis(1, 1)
      expect(result.count).to eq(1)
      expect(result.first.id).to eq(contract.id)

      result = subject.under_analysis(1, 2)
      expect(result).to be_empty
    end

    context "shared contracts" do
      before do
        allow(Features).to receive(:active?).and_call_original
        allow(Features).to receive(:active?).with(Features::SHARED_CONTRACTS).and_return(true)
        create(:product, :with_customer_uploaded_document, :shared_contract, analysis_state: :under_analysis)
      end

      it "does not return shared contracts" do
        contract = create(:contract, :with_customer_uploaded_document, :under_analysis)

        expect(Product.count).to be(3)
        contracts = subject.under_analysis(10, 1)
        expect(contracts.count).to eq(1)
        expect(contracts.first.id).to eq(contract.id)
      end
    end

    context "with revoked mandate" do
      let(:mandate) { create(:mandate, :revoked) }
      let!(:contract) do
        create(:contract, :with_customer_uploaded_document, :under_analysis, customer_id: mandate.id)
      end

      let(:admin) do
        create(:admin)
      end

      it "excludes contracts of revoked mandates" do
        expect(subject.under_analysis(1, 1, admin: admin).count).to eq 0
      end

      context "for admin with view_revoked_mandates permission" do
        before do
          admin.permissions << create(:permission, :view_revoked_mandates)
        end

        it "includes contracts of revoked mandates" do
          result = subject.under_analysis(1, 1, admin: admin)
          expect(result.count).to eq(1)
          expect(result.first.id).to eq(contract.id)
        end
      end
    end
  end

  describe "#under_analysis_count" do
    let(:mandate) { create(:mandate) }
    let!(:contracts) do
      [
        create(:contract, :with_customer_uploaded_document, :under_analysis, customer_id: mandate.id),
        create(:contract, :with_customer_uploaded_document, :details_complete)
      ]
    end

    it "returns valid count" do
      expect(subject.under_analysis_count).to eq 1
    end

    context "shared contracts" do
      before do
        allow(Features).to receive(:active?).and_call_original
        allow(Features).to receive(:active?).with(Features::SHARED_CONTRACTS).and_return(true)
        create(:product, :with_customer_uploaded_document, :shared_contract, analysis_state: :under_analysis)
      end

      it "only counts non shared contracts" do
        expect(Product.count).to be(3)
        expect(subject.under_analysis_count).to eq 1
      end
    end

    context "with revoked mandate" do
      let(:mandate) { create(:mandate, :revoked) }

      let(:admin) do
        create(:admin)
      end

      it "excludes contracts of revoked mandates" do
        expect(subject.under_analysis_count(admin: admin)).to eq 0
      end

      context "for admin with view_revoked_mandates permission" do
        before do
          admin.permissions << create(:permission, :view_revoked_mandates)
        end

        it "includes contracts of revoked mandates" do
          expect(subject.under_analysis_count(admin: admin)).to eq 1
        end
      end
    end
  end

  describe "#under_analysis_documents_count" do
    let!(:contract) { create(:contract, :with_customer_uploaded_document, :under_analysis) }

    let(:product) { Product.find(contract.id) }

    it "returns valid count" do
      expect(subject.under_analysis_documents_count).to eq 1
      product.documents << create(:document)
      expect(subject.under_analysis_documents_count).to eq 2

      create(:contract, :with_customer_uploaded_document, :details_complete)
      expect(subject.under_analysis_documents_count).to eq 2
    end

    context "shared contracts" do
      before do
        allow(Features).to receive(:active?).and_call_original
        allow(Features).to receive(:active?).with(Features::SHARED_CONTRACTS).and_return(true)
        create(:product, :with_customer_uploaded_document, :shared_contract, analysis_state: :under_analysis)
      end

      it "only counts non shared contracts documents" do
        expect(Document.count).to be(2)
        expect(subject.under_analysis_documents_count).to eq 1
      end
    end

    context "with revoked mandate" do
      let(:mandate) { create(:mandate, :revoked) }
      let!(:contract) do
        create(:contract, :with_customer_uploaded_document, :under_analysis, customer_id: mandate.id)
      end

      let(:admin) do
        create(:admin)
      end

      it "excludes contracts of revoked mandates" do
        expect(subject.under_analysis_documents_count(admin: admin)).to eq 0
      end

      context "for admin with view_revoked_mandates permission" do
        before do
          admin.permissions << create(:permission, :view_revoked_mandates)
        end

        it "includes contracts of revoked mandates" do
          expect(subject.under_analysis_documents_count(admin: admin)).to eq 1
        end
      end
    end
  end

  describe "#find_contract_with_analysis" do
    let(:product) { create(:product, analysis_state: :details_missing) }

    it "called with contract_id" do
      # when contract_id is invalid
      expect(subject.find_contract_with_analysis(contract_id: 1001)).to be_nil

      # when contract_id is valid
      contract = subject.find_contract_with_analysis(contract_id: product.id)
      expect(contract).to be_a(::Contracts::Entities::ContractWithAnalysisState)
    end
  end

  describe "#update_analysis_state" do
    let(:details_missing_state) { Contracts::Entities::Contract::AnalysisState::DETAILS_MISSING }
    let(:under_analysis_state) { Contracts::Entities::Contract::AnalysisState::UNDER_ANALYSIS }
    let(:product) { create(:product, analysis_state: details_missing_state) }

    it "called with analysis_state" do
      expect {
        subject.update_analysis_state!(product, analysis_state: under_analysis_state)
      }.to change { product.reload.analysis_state }.from(details_missing_state).to(under_analysis_state)
    end
  end

  describe "#find_contract_for_instant_advice" do
    context "shared contract feature" do
      before do
        allow(Features).to receive(:active?).and_call_original
      end

      context "when feature flag is ON" do
        it "returns the contract" do
          allow(Features).to receive(:active?).with(Features::SHARED_CONTRACTS).and_return(true)

          product = create(:product, :shared_contract, analysis_state: :details_missing)
          contract = subject.find_contract_for_instant_advice(product.id)

          expect(contract).to be_kind_of ::Contracts::Constituents::InstantAdvice::Entities::Contract
          expect(contract.id).to be(product.id)
        end
      end

      context "when feature flag is OFF" do
        it "returns the contract" do
          allow(Features).to receive(:active?).with(Features::SHARED_CONTRACTS).and_return(false)

          product = create(:product, :shared_contract, analysis_state: :details_missing)
          contract = subject.find_contract_for_instant_advice(product.id)

          expect(contract).to be_nil
        end
      end
    end

    context "when contract exists" do
      it "returns the contract" do
        product = create(:product, analysis_state: :details_missing)
        contract = subject.find_contract_for_instant_advice(product.id)

        expect(contract).to be_kind_of ::Contracts::Constituents::InstantAdvice::Entities::Contract
        expect(contract.id).to be(product.id)
      end
    end

    context "when contract does not exist" do
      it "returns nil" do
        non_existing_contract_id = 890
        contract = subject.find_contract_for_instant_advice(non_existing_contract_id)

        expect(contract).to be_nil
      end
    end
  end
end
