# frozen_string_literal: true

require "rails_helper"
require "composites/customer/repositories/customer_repository"

RSpec.describe Customer::Repositories::CustomerRepository, :integration do
  subject(:repo) { described_class.new }

  describe "#create_prospect!" do
    let(:ip) { Faker::Internet.ip_v4_address }
    let(:installation_id) { Faker::Internet.device_token }

    it "returns entity with aggregated data" do
      customer = repo.create_prospect!(ip, installation_id)
      expect(customer).to be_kind_of Customer::Entities::Customer

      expect(customer.id).not_to be_blank
      expect(customer.mandate_state).to eq "not_started"
      expect(customer.customer_state).to eq "prospect"

      expect(customer.source_data["anonymous_lead"]).to eq true
      expect(customer.registered_with_ip).to eq ip
      expect(customer.installation_id).to eq installation_id
    end

    it "creates a new mandate" do
      customer = repo.create_prospect!(ip)
      expect(Mandate.find_by(id: customer.id)).not_to be_blank
    end

    it "creates a new lead" do
      customer = repo.create_prospect!(ip, installation_id)
      lead = Lead.find_by(mandate_id: customer.id)
      expect(lead.installation_id).to eq(customer.installation_id)
    end
  end

  describe "#installation_id_exists?" do
    let(:lead) { create :device_lead }
    let(:user) { create :user, :with_installation_id }

    it "returns boolean result" do
      # returns true when installation_id exists
      expect(repo.installation_id_exists?(lead.installation_id)).to eq(true)
      expect(repo.installation_id_exists?(user.installation_id)).to eq(true)

      # returns false when installation_id doesn't exist
      expect(repo.installation_id_exists?("rand12345678")).to eq(false)
    end
  end

  describe "#find" do
    it "returns entity with aggregated data" do
      mandate = create(
        :mandate,
        state: "not_started",
        customer_state: "self_service",
        user: build(:user)
      )

      customer = repo.find(mandate.id)
      expect(customer).to be_kind_of Customer::Entities::Customer

      expect(customer.id).not_to be_blank
      expect(customer.mandate_state).to eq "not_started"
      expect(customer.customer_state).to eq "self_service"

      expect(customer.registered_with_ip).to be_nil
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repo.find(999)).to be_nil
      end
    end
  end

  describe "#find_by_installation_id" do
    it "returns lead with aggregated data" do
      lead = create(:device_lead, :with_mandate)

      customer = repo.find_by_installation_id(lead.installation_id)
      expect(customer).to be_kind_of Customer::Entities::Customer
      expect(customer.id).to eql(lead.mandate_id)
    end

    it "returns user with aggregated data" do
      user = create(:device_user, :with_mandate)

      customer = repo.find_by_installation_id(user.installation_id)
      expect(customer).to be_kind_of Customer::Entities::Customer
      expect(customer.id).to eql(user.mandate_id)

      device = create(:device, user: user)
      customer = repo.find_by_installation_id(device.installation_id)
      expect(customer).to be_kind_of Customer::Entities::Customer
      expect(customer.id).to eql(user.mandate_id)
    end

    context "when customer does not exist" do
      it "returns nil" do
        expect(repo.find_by_installation_id(999)).to be_nil
      end
    end
  end

  describe "#update!" do
    let!(:admin) { create(:admin) }
    let(:installation_id) { Faker::Internet.device_token }

    it "passes scenario" do
      customer = create(:customer, :prospect)
      expect {
        repo.update!(customer.id, mandate_state: :created)
      }.to change(Interaction, :count).by(0)
      mandate = Mandate.find(customer.id)
      expect(mandate.state).to eq("created")

      # updates lead attributes
      repo.update!(customer.id, installation_id: installation_id)
      mandate = Mandate.find(customer.id)
      expect(mandate.lead.installation_id).to eq(installation_id)
    end
  end
end
