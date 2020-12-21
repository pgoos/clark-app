# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Repositories::AoaRequestBusinessEventRepository, :integration do
  let(:opportunity) { create :opportunity }
  let!(:request) { { data: "request_data" } }
  let!(:response) { { data: "response_data" } }

  describe "#create!" do
    context "create an aoa requested business event" do
      it "passes to audit the correct parameters" do
        expect(BusinessEvent)
          .to receive(:audit).with(opportunity, "aoa_requested", { request: request, response: response })
        subject.create!(opportunity, request, response)
      end
    end
  end
end
