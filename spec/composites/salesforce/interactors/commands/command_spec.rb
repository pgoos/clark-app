# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/interactors/commands/command"

RSpec.describe Salesforce::Interactors::Commands::Command, :integration do
  it "calls opportunity_offer_sent command" do
    params = { type: "opportunity-offer-sent", aggregate_id: 1, payload: {} }
    expect(Salesforce::Container).to receive(:resolve)
      .with("public.interactors.commands.opportunity_offer_sent").and_return(double(call: nil))
    object = described_class.new
    result = object.call(params)
    expect(result).to be_successful
  end

  it "calls opportunity_reassign command" do
    params = {
      "type" => "opportunity-assigned", "revision" => nil, "predecessor" => nil,
      "payload" => { "admin_email" => "yuvaraja.blamurugan@clark.de" },
      "occured_at" => "2020-11-12T16:46:50.000Z", "id" => "10", "country" => "de",
      "aggregate_type" => "opportunity", "aggregate_id" => 9
    }
    expect(Salesforce::Container).to receive(:resolve)
      .with("public.interactors.commands.opportunity_reassign").and_return(double(call: nil))
    object = described_class.new
    result = object.call(params)
    expect(result).to be_successful
  end
end
