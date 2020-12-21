# frozen_string_literal: true

require "rails_helper"
require "composites/customer/repositories/customer_repository"

RSpec.describe Customer::Constituents::UpgradeJourney::Repositories::CustomerRepository, :integration do
  subject(:repo) { described_class.new }

  let(:state) { "not_started" }
  let(:customer_state) { "self_service" }
  let(:upgrade_journey_state) { "signature" }

  let(:mandate) do
    create(
      :mandate,
      :wizard_profiled,
      state: state,
      customer_state: customer_state
    )
  end

  describe "#find" do
    it "returns an entity" do
      customer = repo.find(mandate.id)
      expect(customer).to be_kind_of Customer::Constituents::UpgradeJourney::Entities::Customer

      expect(customer.id).not_to be_blank
      expect(customer.mandate_state).to eq state
      expect(customer.customer_state).to eq customer_state
      expect(customer.upgrade_journey_state).to eq upgrade_journey_state
      expect(customer.profile).to be_nil
    end

    it "returns customer including profile" do
      customer = repo.find(mandate.id, include_profile: true)
      expect(customer).to be_kind_of Customer::Constituents::UpgradeJourney::Entities::Customer
      expect(customer.profile).to be_kind_of Customer::Entities::Profile
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repo.find(999)).to be_nil
      end
    end
  end

  describe "#update!" do
    let(:upgrade_journey_state) { "signature" }

    let(:new_state) { "created" }
    let(:new_customer_state) { "mandate_customer" }
    let(:new_upgrade_journey_state) { "finished" }

    context "fails on validation" do
      let(:new_state) { "invalid_state" }

      it do
        expect { repo.update!(mandate.id, mandate_state: new_state) }
          .to raise_error(Utils::Repository::Errors::ValidationError)
      end
    end

    context "updates mandate states" do
      it do
        repo.update!(
          mandate.id,
          mandate_state: new_state,
          customer_state: new_customer_state,
          upgrade_journey_state: new_upgrade_journey_state
        )

        mandate.reload

        expect(mandate.state).to eq new_state
        expect(mandate.customer_state).to eq new_customer_state
        expect(mandate.wizard_steps).to eq %w[profiling confirming]
      end
    end

    context "with business event" do
      it "creates new business event" do
        expect(BusinessEvent).to receive(:audit).with(mandate, :foo)

        repo.update!(
          mandate.id,
          { customer_state: "mandate_customer" },
          audit_business_event: :foo
        )
      end
    end
  end

  describe "#create_signature!" do
    let(:with_bid_data) { fixture_file_upload("#{Rails.root}/spec/fixtures/files/blank.pdf") }
    let(:no_bio_data)   { fixture_file_upload("#{Rails.root}/spec/fixtures/files/blank.pdf") }
    let(:png_signature) { fixture_file_upload("#{Rails.root}/spec/fixtures/empty_signature.png") }
    let!(:admin) { create(:admin) }

    it "creates the mandate documents" do
      mandate = create(:mandate)

      repo.create_signature!(
        mandate.id,
        Base64.encode64(with_bid_data.read),
        Base64.encode64(no_bio_data.read),
        Base64.encode64(png_signature.read)
      )

      expect(mandate.documents.size).to eq 2

      expect(mandate.documents[0].document_type.key).to eq "mandate_biometric"
      expect(mandate.documents[0].content_type).to eq "application/pdf"

      expect(mandate.documents[1].document_type.key).to eq "mandate"
      expect(mandate.documents[1].content_type).to eq "application/pdf"

      expect(mandate.signature).to be_present
    end
  end
end
