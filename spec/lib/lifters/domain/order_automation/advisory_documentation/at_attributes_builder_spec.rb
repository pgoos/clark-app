# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::OrderAutomation::AdvisoryDocumentation::AtAttributesBuilder do
  subject do
    described_class.new(
      product: product, admin: admin, old_product: old_product,
      opportunity: opportunity, opportunity_source: []
    )
  end

  let(:mandate) { create(:mandate) }
  let(:product) do
    create(:product, mandate: mandate, contract_started_at: Date.today - 5.days,
           contract_ended_at: Date.today - 2.days)
  end
  let(:old_product) { create(:product) }
  let(:admin) { create(:admin) }
  let(:offer) { create(:offer) }
  let(:offer_option) { create(:offer_option, offer: offer, product: product) }
  let(:opportunity) { create(:opportunity, offer: offer) }

  describe "#locals" do
    let(:locals) { subject.locals }

    before do
      allow(I18n).to receive(:t).and_call_original
      allow(I18n)
        .to receive(:t)
        .with("pdf_generator.advisory_documentation.confirmation_of_privacy")
        .and_return({ heading: "heading", text: "text" })
      allow(I18n)
        .to receive(:t)
        .with("pdf_generator.advisory_documentation.access_to_declarations")
        .and_return({ heading: "heading", text: "text" })
    end

    it "returns proper hash" do
      expect(locals.keys).to eq(
        %i[path_to_footer mandate product admin doc_date introduction company_data
           mediation_info advisory_interaction_info client_wishes criteria_for_closing_the_contract
           advisory_decision documents liability_note answers category_name confirmation_of_privacy
           access_to_declarations insurance_situation recommendation reason_for_consultation
           pros_and_cons]
      )
    end

    it "returns properly formatted locals for generator" do
      expect(locals[:introduction].keys).to eq %i[heading value]
      expect(locals[:company_data].keys).to eq %i[heading values]
      expect(locals[:mediation_info].keys)
        .to eq %i[heading complaint_management legal_service ministry_info]
      expect(locals[:advisory_interaction_info].keys).to eq %i[heading values]
      expect(locals[:client_wishes].keys).to eq %i[heading value]
      expect(locals[:criteria_for_closing_the_contract].keys).to eq %i[heading values]
      expect(locals[:advisory_decision].keys)
        .to eq %i[heading coverage_wishes_text objective_comparison_text decision_heading decision product_values]
      expect(locals[:documents].keys).to eq %i[heading values]
      expect(locals[:liability_note].keys).to eq %i[heading value]
      expect(locals[:answers].keys).to eq %i[heading values note]
      expect(locals[:confirmation_of_privacy].keys).to eq %i[heading value]
      expect(locals[:access_to_declarations].keys).to eq %i[heading value]
    end

    it "passes admin name to generator" do
      expect(locals[:advisory_interaction_info][:values][0][:value]).to include(opportunity.admin.name)
    end

    context "contract_ended_at not set" do
      let(:product) do
        create(:product, mandate: mandate, contract_started_at: Date.today - 5.days,
          contract_ended_at: nil)
      end

      it "returns properly formatted locals for generator" do
        expect(locals[:criteria_for_closing_the_contract].keys).to eq %i[heading values]
      end
    end

    context "opportunity has interactions" do
      let!(:interactions) do
        [
          create(:interaction_phone_call, topic: opportunity),
          create(:incoming_message, topic: opportunity)
        ]
      end

      let(:advisory_interaction_info) do
        advisory_interaction_info = locals[:advisory_interaction_info][:values].find do |info|
          info[:label] == I18n.t("pdf_generator.advisory_documentation.advisory_interaction.labels.interaction_types")
        end
        advisory_interaction_info[:value]
      end

      it "returns interaction types in advisory_interaction_info" do
        expect(advisory_interaction_info).to include(
          I18n.t("pdf_generator.advisory_documentation.advisory_interaction.types.Interaction::Message"),
          I18n.t("pdf_generator.advisory_documentation.advisory_interaction.types.Interaction::PhoneCall")
        )
      end
    end
  end
end
