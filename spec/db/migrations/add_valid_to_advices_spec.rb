# frozen_string_literal: true

require "rails_helper"

require "migration_data/testing"
require_migration "add_valid_to_advices"

RSpec.describe AddValidToAdvices, :integration do
  describe "#data" do
    let(:product) { create(:product) }
    let(:initial_metadata) do
      {
        "created_by_robo_advisor" => true,
        "reoccurring_advice" => true
      }
    end

    context "interaction is advice" do
      let(:expected_metadata) { initial_metadata.merge("valid" => true) }
      let(:interaction) do
        Interaction::Advice.skip_callback(:create, :before, :set_default_values)
        advice_object = create(:advice, metadata: initial_metadata)
        Interaction::Advice.set_callback(:create, :before, :set_default_values)
        advice_object
      end

      it "adds valid to metadata" do
        expect(interaction.metadata).to eq initial_metadata
        described_class.new.up
        expect(interaction.reload.metadata).to eq expected_metadata
      end
    end

    context "interaction is not advice" do
      let(:expected_metadata) { initial_metadata }
      let(:interaction) do
        create(:interaction_phone_call, metadata: initial_metadata)
      end

      it "does not add valid to metadata" do
        expect(interaction.metadata).to eq initial_metadata
        described_class.new.up
        expect(interaction.reload.metadata).to eq expected_metadata
      end
    end
  end
end
