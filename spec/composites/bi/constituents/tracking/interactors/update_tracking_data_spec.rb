# frozen_string_literal: true

require "rails_helper"

RSpec.describe BI::Constituents::Tracking::Interactors::UpdateTrackingData do
  subject(:update) do
    described_class.new(visit_repo: visit_repo, customer_repo: customer_repo)
  end

  let(:customer_repo) { double :repo, update!: nil }
  let(:visit_repo) { double :repo, update!: visit }

  let(:visit) { double :visit, customer_id: nil }

  it "updates a visit" do
    expect(visit_repo).to receive(:update!).with("VISIT_ID", { "network" => "foo" })
    result = update.("VISIT_ID", { "network" => "foo" })
    expect(result).to be_successful
  end

  context "when there is a customer attached to visit" do
    let(:visit) { double :visit, customer_id: "CUSTOMER_ID" }

    it "updates customer" do
      expect(customer_repo).to receive(:update!).with("CUSTOMER_ID", { "network" => "foo" })
      result = update.("VISIT_ID", { "network" => "foo" })
      expect(result).to be_successful
    end
  end
end
