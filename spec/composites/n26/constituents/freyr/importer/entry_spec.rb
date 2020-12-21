# frozen_string_literal: true

require "rails_helper"
require "composites/n26/constituents/freyr/importer/entry"
require "composites/n26/constituents/freyr/repositories/customer_repository"

RSpec.describe N26::Constituents::Freyr::Importer::Entry do
  subject(:entry) { described_class.new(mandate_id, email, phone_number, customer_repo: customer_repo) }

  let(:customer_repo) do
    instance_double(
      N26::Constituents::Freyr::Repositories::CustomerRepository,
      find: customer,
      mark_as_imported: customer,
      update_email: true,
      save_phone_number!: true
    )
  end

  let(:customer) { double(id: mandate_id, email: email, owned_by_n26?: true) }
  let(:mandate_id) { Faker::Number.number(digits: 4) }
  let(:email) { Faker::Internet.email }
  let(:phone_number) { "491771661232" }

  describe "#valid?" do
    context "when provided data are not valid" do
      it "returns false when mandate_id is missing" do
        entry = described_class.new("", email, phone_number)

        expect(entry).not_to be_valid
        expect(entry.errors).not_to be_empty
      end

      it "returns false when email is missing" do
        entry = described_class.new(mandate_id, "", phone_number)

        expect(entry).not_to be_valid
        expect(entry.errors).not_to be_empty
      end

      it "returns false when phone_number is missing" do
        entry = described_class.new(mandate_id, email, "")

        expect(entry).not_to be_valid
        expect(entry.errors).not_to be_empty
      end

      it "returns false when phone_number is not right format" do
        entry = described_class.new(mandate_id, email, "+49123")

        expect(entry).not_to be_valid
        expect(entry.errors).not_to be_empty
      end
    end

    context "when provided data are valid" do
      it "returns true" do
        entry = described_class.new(mandate_id, email, phone_number)

        expect(entry).to be_valid
        expect(entry.errors).to be_empty
      end
    end
  end

  describe "#save!" do
    context "when provided data are not valid" do
      let(:entry) { described_class.new(mandate_id, email, nil) }

      it "returns false" do
        expect(entry.save).to be_falsey
      end
    end

    context "when the customer can not be found" do
      before do
        allow(customer_repo).to receive(:find).and_return(nil)
      end

      it "returns false" do
        expect(entry.save).to be_falsey
      end
    end

    context "when customer is not owned by n26" do
      before do
        allow(customer).to receive(:owned_by_n26?).and_return(false)
      end

      it "returns false" do
        expect(entry.save).to be_falsey
      end
    end

    context "when provided data are valid" do
      it "saves phone number" do
        expect(customer_repo).to receive(:save_phone_number!).with(customer.id, "+#{phone_number}")
        entry.save
      end

      it "updates email" do
        expect(customer_repo).to receive(:update_email).with(customer, email)
        entry.save
      end

      it "marks customer as imported" do
        expect(customer_repo).to receive(:mark_as_imported).with(customer)
        entry.save
      end

      it "returns true" do
        entry.save
        expect(entry.save).to be_truthy
      end
    end
  end
end
