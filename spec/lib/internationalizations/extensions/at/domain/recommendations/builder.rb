# frozen_string_literal: true

require "rails_helper"

RSpec.describe Extensions::At::Domain::Recommendations::Builder do
  describe "#filter_categories" do
    let(:builder) { Domain::Recommendations::Builder }
    let(:category_idents) {
      %w[PHV_IDENT 08e4af50 0218c56d]
    }
    let(:phv_ident) { "PHV_IDENT" }
    let(:mandate) { create(:mandate) }
    let(:subject) { described_class.filter_categories(builder, category_idents, mandate) }

    before { stub_const("Domain::Recommendations::Builder::PHV_IDENT", phv_ident) }

    context "when custom filter should remove PHV" do
      before { allow(described_class).to receive(:remove_phv?).and_return(true) }

      it "should remove PHV from categories ident" do
        expect(subject).not_to include(phv_ident)
      end
    end

    context "when custom filter should not remove PHV" do
      before { allow(described_class).to receive(:remove_phv?).and_return(false) }

      it "should remove PHV from categories ident" do
        expect(subject).to include(phv_ident)
      end
    end
  end
end
