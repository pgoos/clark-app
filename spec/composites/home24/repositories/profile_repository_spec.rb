# frozen_string_literal: true

require "rails_helper"
require "composites/home24/repositories/profile_repository"

RSpec.describe Home24::Repositories::ProfileRepository, :integration do
  subject(:repo) { described_class.new }

  let(:mandate) { create(:mandate, :home24, :with_phone) }

  describe "#find" do
    it "returns entity with aggregated data" do
      profile = repo.find(mandate.id, include_address: true, include_phone: true)

      expect(profile).to be_kind_of Home24::Entities::Profile
      expect(profile.customer_id).to eq mandate.id
      expect(profile.email).to eq mandate.email
      expect(profile.first_name).to eq mandate.first_name
      expect(profile.last_name).to eq mandate.last_name
      expect(profile.birthdate).to eq mandate.birthdate
      expect(profile.gender).to eq mandate.gender
      expect(profile.address).to be_kind_of Home24::Entities::Address
      expect(profile.phone).to be_kind_of Home24::Entities::Phone
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repo.find(999)).to be_nil
      end
    end
  end
end
