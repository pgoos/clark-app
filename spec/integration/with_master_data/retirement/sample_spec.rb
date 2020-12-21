# frozen_string_literal: true

require "rails_helper"

RSpec.describe "sample to be removed", :integration, :retirement, :clark_with_master_data do
  #include_context "retirement integration fixtures"

  it "checks that deathies are there" do
    expect(Retirement::Deathy.count).to eq(124)
  end
end
