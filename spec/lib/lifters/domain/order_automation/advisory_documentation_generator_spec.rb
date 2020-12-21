# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OrderAutomation::AdvisoryDocumentationGenerator, :integration do
  let(:current_admin) { create(:admin) }
  let(:admin) { create(:admin) }
  let(:opportunity) { create(:opportunity) }
  let(:questionnaire) { create(:questionnaire) }
  let(:offer) { create(:offer, opportunity: opportunity) }
  let(:offer_option) { create(:offer_option, offer: offer) }
  let(:category) { create(:category, ident: "03b12732") }
  let(:plan) { create(:plan, insurance_tax: 10) }
  let(:product) do
    create(:product,
           category: category, offer_option: offer_option,
           contract_ended_at: Time.zone.now, contract_started_at: 1.year.ago, plan: plan)
  end

  describe "#pdf" do
    it "generates advisory document from template" do
      generator = described_class.new(
        product: product, admin: admin,
        opportunity: opportunity, opportunity_source: questionnaire
      )

      html = Nokogiri::HTML(generator.generate_html)

      expect(html.css("header h1").first.text).to include "Beratungsdokumentation"
      expect(html.css("header h1").first.text).to include product.category.name

      expect(html.css(".cn-title-page .title-full-name").text).to eq product.mandate.full_name
    end
  end
end
