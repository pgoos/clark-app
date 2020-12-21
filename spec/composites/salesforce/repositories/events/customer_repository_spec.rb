# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/repositories/events/customer_repository"

RSpec.describe Salesforce::Repositories::Events::CustomerRepository do
  subject(:repository) { described_class.new }

  let!(:user) { create(:user, last_sign_in_at: DateTime.current) }
  let!(:mandate) { create(:mandate, :accepted, user: user) }

  context "Mandate accept" do
    describe "#find" do
      it "returns event" do
        event = repository.find(mandate.id, "Mandate", "demand-check-completed")
        expect(event.id).to eq mandate.id
        expect(event.country).to eq "de"
        expect(event.aggregate_type).to eq "customer"
        expect(event.aggregate_id).to eq mandate.id
        expect(event.sequence).to eq 1
        expect(event.type).to eq "customer-demand-check-completed"
        expect(event.revision).to eq 1
        expect(event).to be_kind_of Salesforce::Entities::Events::Envelop
      end

      context "when event does not exist" do
        it "returns nil" do
          expect(repository.find(9999, "Mandate", "accept")).to be_nil
        end
      end
    end
  end
end
