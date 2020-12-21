# frozen_string_literal: true

RSpec.shared_examples "a source namable model" do
  let(:instance_name) { ActiveModel::Naming.singular(described_class) }
  let(:instance)      { create(instance_name) }

  describe "public instance methods" do
    context "responds to its methods" do
      it { expect(instance).to respond_to(:update_partner_source_network) }
    end

    context ".update_partner_source_network" do
      context "when adjust field of source data is empty" do
        it "sets network value" do
          new_source_data = {"adjust" => {"network" => "partner"}}
          instance.source_data = {}
          instance.update_partner_source_network("partner")
          expect(instance.source_data).to eq(new_source_data)
        end
      end

      context "when adjust field of source data has any info" do
        it "only updates network field" do
          instance.source_data = {"adjust" => {"network" => "TV-Smiles", "token" => "abc"}}
          new_source_data      = {"adjust" => {"network" => "partner",   "token" => "abc"}}

          instance.update_partner_source_network("partner")
          expect(instance.source_data).to eq(new_source_data)
        end
      end
    end
  end
end
