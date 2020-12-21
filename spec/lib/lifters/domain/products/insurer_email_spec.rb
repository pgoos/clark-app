# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Products::InsurerEmail do
  subject(:build) { described_class.new }

  let(:product) { object_double Product.new, subcompany: subcompany, company: company }
  let(:subcompany) { nil }
  let(:company) { nil }

  context "when neither company nor subcompany have email" do
    it "returns nil" do
      expect(build.(product)).to be_nil
    end
  end

  context "with subcompany email" do
    let(:subcompany) { object_double Subcompany.new, info_email: "SUB_EMAIL" }

    it "returns email of subcompany" do
      expect(build.(product)).to eq "SUB_EMAIL"
    end
  end

  context "with company email" do
    let(:company) { object_double Company.new, info_email: "COMP_EMAIL" }

    it "returns email of subcompany" do
      expect(build.(product)).to eq "COMP_EMAIL"
    end
  end

  context "with company and subcompany emails" do
    let(:subcompany) { object_double Subcompany.new, info_email: "SUB_EMAIL" }
    let(:company) { object_double Company.new, info_email: "COMP_EMAIL" }

    it "returns email of subcompany" do
      expect(build.(product)).to eq "SUB_EMAIL"
    end
  end
end
