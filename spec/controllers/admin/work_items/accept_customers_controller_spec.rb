# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::WorkItems::AcceptCustomersController, :integration, type: :controller do
  let(:admin) { create(:super_admin) }

  before { sign_in(admin) }

  describe "POST /accept_customers/:id/request_corrections" do
    let(:result) { double :result, failure?: false }

    before do
      allow(Customer).to receive(:request_corrections_in_upgrade).with(mandate.id).and_return result
      allow(Domain::AcceptCustomers::Processes).to receive(:request_corrections_process)

      patch :request_corrections, params: { locale: :de, id: mandate.id }
    end

    context "with clark2 customer" do
      let(:mandate) { create :mandate, :created, customer_state: :mandate_customer }

      it "requests corrections" do
        expect(Customer).to have_received(:request_corrections_in_upgrade).with(mandate.id)
      end
    end

    context "with clark1 customer" do
      let(:mandate) { create :mandate, :created }

      it "requests corrections" do
        expect(Domain::AcceptCustomers::Processes).to have_received(:request_corrections_process).with(mandate)
      end
    end
  end
end
