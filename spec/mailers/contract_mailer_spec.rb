# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContractMailer, :integration, type: :mailer do
  let(:mandate) { create(:mandate, :with_user) }

  before do
    allow(Mandate).to receive(:find).with(mandate.id).and_return(mandate)
  end

  describe "contract_mailer_request_correction" do
    let(:category_name) { "Some category" }
    let(:additional_information) { "please reupload document" }
    let(:documentable) { mandate }
    let(:document_type) { DocumentType.request_correction }
    let(:mail) do
      ContractMailer.request_correction(
        mandate.id,
        category_name,
        [:insurance_number],
        additional_information
      )
    end

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "notify_contract_cancellation" do
    let(:product) { create(:product, mandate: mandate) }
    let(:documentable) { product }
    let(:document_type) { DocumentType.notify_contract_cancellation }
    let(:mail) { ContractMailer.notify_contract_cancellation(product.id) }

    it_behaves_like "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "notify_contract_cancellation_general_sold_by_us_known_end_date" do
    let(:product) { create(:product, mandate: mandate, contract_ended_at: Date.new(2021, 1, 9)) }
    let(:documentable) { product }
    let(:document_type) { DocumentType.notify_contract_cancellation_general_sold_by_us_known_end_date }
    let(:mail) { ContractMailer.notify_contract_cancellation_general_sold_by_us_known_end_date(product.id) }

    it_behaves_like "checks mail rendering" do
      let(:html_part) { ".action-button" }
    end
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "notify_contract_cancellation_general_sold_by_us_unknown_end_date" do
    let(:product) { create(:product, mandate: mandate) }
    let(:documentable) { product }
    let(:document_type) { DocumentType.notify_contract_cancellation_general_sold_by_us_unknown_end_date }
    let(:mail) { ContractMailer.notify_contract_cancellation_general_sold_by_us_unknown_end_date(product.id) }

    it_behaves_like "checks mail rendering" do
      let(:html_part) { ".action-button" }
    end
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "notify_contract_cancellation_general_sold_by_others_known_end_date" do
    let(:product) { create(:product, mandate: mandate, contract_ended_at: Date.new(2021, 4, 14)) }
    let(:documentable) { product }
    let(:document_type) { DocumentType.notify_contract_cancellation_general_sold_by_others_known_end_date }
    let(:mail) { ContractMailer.notify_contract_cancellation_general_sold_by_others_known_end_date(product.id) }

    it_behaves_like "checks mail rendering" do
      let(:html_part) { ".action-button" }
    end
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "notify_contract_cancellation_general_sold_by_others_unknown_end_date" do
    let(:product) { create(:product, mandate: mandate, contract_ended_at: nil) }
    let(:documentable) { product }
    let(:document_type) { DocumentType.notify_contract_cancellation_general_sold_by_others_unknown_end_date }
    let(:mail) { ContractMailer.notify_contract_cancellation_general_sold_by_others_unknown_end_date(product.id) }

    it_behaves_like "checks mail rendering" do
      let(:html_part) { ".action-button" }
    end
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "kfz_contract_cancellation_best_direct_insurer_known_end_date" do
    let(:product) { create(:product, mandate: mandate, contract_ended_at: Date.new(2021, 4, 14)) }
    let(:documentable) { product }
    let(:document_type) { DocumentType.kfz_contract_cancellation_best_direct_insurer_known_end_date }
    let(:mail) { ContractMailer.kfz_contract_cancellation_best_direct_insurer_known_end_date(product.id) }

    it_behaves_like "checks mail rendering" do
      let(:html_part) { ".action-button" }
    end
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "kfz_contract_cancellation_best_direct_insurer_unknown_end_date" do
    let(:product) { create(:product, mandate: mandate, contract_ended_at: nil) }
    let(:documentable) { product }
    let(:document_type) { DocumentType.kfz_contract_cancellation_best_direct_insurer_unknown_end_date }
    let(:mail) { ContractMailer.kfz_contract_cancellation_best_direct_insurer_unknown_end_date(product.id) }

    it_behaves_like "checks mail rendering" do
      let(:html_part) { ".action-button" }
    end
    it_behaves_like "tracks document and mandate in ahoy email"
  end
end
