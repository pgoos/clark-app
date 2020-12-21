# frozen_string_literal: true

require "rails_helper"
require "composites/home24/repositories/phone_repository"

RSpec.describe Home24::Repositories::PhoneRepository, :integration do
  subject(:repo) { described_class.new }

  let(:mandate) { create(:mandate, :home24, :with_phone) }

  describe "#find_by" do
    it "returns entity with aggregated data" do
      phone = repo.find_by(customer_id: mandate.id)
      phone_ar_model = mandate.phones.first

      expect(phone).to be_kind_of Home24::Entities::Phone
      expect(phone.id).to eq phone_ar_model.id
      expect(phone.number).to eq phone_ar_model.number
      expect(phone.primary).to eq phone_ar_model.primary
      expect(phone.mandate_id).to eq phone_ar_model.mandate_id
    end

    context "when there is no phone associated with customer_id" do
      let(:mandate) { create(:mandate, :home24) }

      it "returns nil" do
        expect(repo.find_by(customer_id: 999)).to be_nil
      end
    end
  end
end
