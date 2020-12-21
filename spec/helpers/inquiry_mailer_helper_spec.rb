# frozen_string_literal: true

require "rails_helper"

RSpec.describe InquiryMailerHelper, type: :helper do
  let(:generic_company) { instance_double(Company, ident: "generic_company") }

  it "resolves the generic path" do
    expect(body_partial_path(generic_company.ident))
      .to eq("inquiry_mailer/insurance_requests/generic")
  end

  it "resolves the path for Allianz Versicherungen with the ident allia8c23e2" do
    allianz = instance_double(Company, ident: "allia8c23e2")

    expect(body_partial_path(allianz.ident))
      .to eq("inquiry_mailer/insurance_requests/allia8c23e2")
  end
end
