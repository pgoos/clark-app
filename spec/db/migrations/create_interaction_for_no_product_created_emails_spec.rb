# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "create_interaction_for_no_product_created_emails"

RSpec.describe CreateInteractionForNoProductCreatedEmails, :integration do
  describe "#data" do
    it "does not raise an exception" do
      expect { subject.data }.not_to raise_exception
    end

    context "with data" do
      let(:inquiry) { create(:inquiry) }
      let(:inquiry_category) { create(:inquiry_category, inquiry: inquiry) }
      let!(:document_wanted) do
        create :document, document_type: DocumentType.no_product_can_be_created,
                          documentable: inquiry_category
      end
      let!(:document_unwanted) { create(:document, documentable: inquiry_category.inquiry) }
      let!(:admin) { create(:admin) }

      it "should create an interaction" do
        expect {
          subject.data
        }.to change(Interaction::Email, :count).by(1)
      end

      it "should create the interaction with correct data" do
        subject.data

        interaction = Interaction::Email.last

        expect(interaction.mandate).to eq inquiry_category.inquiry.mandate
        expect(interaction.admin).to eq admin
        expect(interaction.topic).to eq inquiry
        expect(interaction.direction).to eq "out"
        expect(interaction.content).to eq "Rückfrage zu deinem Vertrag"
        expect(interaction.title).to eq "no product can be created"
        expect(interaction.created_at).to be_within(5.minutes).of(document_wanted.created_at)
      end
    end
  end

  describe "#rollback" do
    before do
      create(:interaction_email, metadata: {title: "no product can be created"})
      create(:interaction_email, metadata: {title: "something else"})
    end

    it "should delete no product can be created interactions" do
      expect {
        subject.rollback
      }.to change(Interaction::Email, :count).by(-1)
    end
  end
end
