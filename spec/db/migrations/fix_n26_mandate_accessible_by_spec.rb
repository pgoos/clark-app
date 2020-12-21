# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "fix_n26_mandate_accessible_by"

RSpec.describe FixN26MandateAccessibleBy, :integration do
  let(:mandate_id) { 649260 }
  let(:accessible_by_n26) { %w[clark n26] }
  let(:accessible_by_clark) { %w[clark] }

  describe "#up" do
    context "mandate does not exist" do
      it "finishes the rake task" do
        expect(described_class.new.up).to be_nil
      end
    end

    context "mandate exists" do
      context "and is accessible by n26" do
        let!(:mandate) { create(:mandate, id: mandate_id, accessible_by: accessible_by_n26) }

        it "removes mandate's access by n26" do
          described_class.new.up
          expect(mandate.accessible_by).to eq(accessible_by_clark)
        end
      end

      context "and is inaccessible by n26" do
        let!(:mandate) { create(:mandate, id: mandate_id, accessible_by: accessible_by_clark) }

        it "does not change the mandate accessible_by" do
          described_class.new.up
          expect(mandate.reload.accessible_by).to eq(accessible_by_clark)
        end
      end
    end
  end

  describe "#down" do
    context "mandate does not exist" do
      it "finishes the rake task" do
        expect(described_class.new.down).to be_nil
      end
    end

    context "mandate exists" do
      context "and is accessible by n26" do
        let!(:mandate) { create(:mandate, id: mandate_id, accessible_by: accessible_by_n26) }

        it "does not change the mandate accessible_by" do
          described_class.new.down
          expect(mandate.reload.accessible_by).to eq(accessible_by_n26)
        end
      end

      context "and is not accessible by n26" do
        let!(:mandate) { create(:mandate, id: mandate_id, accessible_by: accessible_by_clark) }

        it "re-enables mandate's access by n26" do
          described_class.new.down
          expect(mandate.reload.accessible_by).to eq(accessible_by_n26)
        end
      end
    end
  end
end
