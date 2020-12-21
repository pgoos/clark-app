# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentImporter::Repositories::CostCenterRepository do
  before do
    create_list(:cost_center, 3)
  end

  let!(:fonds_finanz_cost_center) { create(:cost_center, name: "Fonds Finanz") }

  it "return only Fonds Finanz record" do
    expect(described_class.new.fonds_finanz).to eq(fonds_finanz_cost_center)
  end
end
