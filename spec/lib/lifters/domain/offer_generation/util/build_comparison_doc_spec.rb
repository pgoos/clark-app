# frozen_string_literal: true

require "rails_helper"
require_relative "with_utility_extension"

RSpec.describe Domain::OfferGeneration::Util::BuildComparisonDoc do
  include_context "with utility extension"

  subject do
    with_utility_extension.(offer, Domain::OfferGeneration::Util::BuildComparisonDoc)
  end

  it "should add a comparison document" do
    pdf = "encoded dummy pdf"
    allow(PdfGenerator::Generator)
      .to receive(:pdf_by_template)
      .with("pdf_generator/comparison_document", offer: offer)
      .and_return(pdf)
    expect(offer).to receive(:add_new_offer_comparison).with(pdf)
    subject.build_comparison_doc
  end
end
