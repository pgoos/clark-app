# frozen_string_literal: true

require "rails_helper"

class FakesController < Admin::BaseController
  include Sortify

  has_scope :sorted_by_last_interaction_asc
end

RSpec.describe FakesController, :integration do
  let(:param) { nil }
  let(:chain) { Opportunity.all }

  before { allow(subject).to receive(:params).and_return(order: param) }

  it "orders by id desc on resource table by default" do
    expect(chain).to receive(:reorder).with("opportunities.id desc")
    subject.apply_sorting(chain, Opportunity)
  end

  context "when order field does not contain table name" do
    let(:param) { "state_desc" }

    it "orders by column on resource table" do
      expect(chain).to receive(:reorder).with("opportunities.state desc")
      subject.apply_sorting(chain, Opportunity)
    end
  end

  context "when order field contains valid table and valid column" do
    let(:param) { "offers.mandate_id_desc" }

    it "orders by column on given table" do
      expect(chain).to receive(:reorder).with("offers.mandate_id desc")
      subject.apply_sorting(chain, Opportunity)
    end
  end

  context "when order field contains invalid table" do
    let(:param) { "invalid_table.source_id_desc" }

    it "orders by id desc on resource table" do
      expect(chain).to receive(:reorder).with("opportunities.id desc")
      subject.apply_sorting(chain, Opportunity)
    end
  end

  context "when order field contains valid table and invalid column" do
    let(:param) { "offers.invalid_column_desc" }

    it "orders by id desc on resource table" do
      expect(chain).to receive(:reorder).with("opportunities.id desc")
      subject.apply_sorting(chain, Opportunity)
    end
  end

  context "with scope name" do
    let(:param) { "sorted_by_last_interaction_asc" }

    it "calls scope on a resource" do
      expect(chain).to receive("sorted_by_last_interaction_asc")
      subject.apply_sorting(chain, Opportunity)
    end
  end

  context "when column is of type datetime" do
    let(:param) { "offers.created_at_asc" }

    it "orders by column with nulls last" do
      expect(chain).to receive(:reorder).with("offers.created_at asc NULLS LAST")
      subject.apply_sorting(chain, Opportunity)
    end
  end
end
