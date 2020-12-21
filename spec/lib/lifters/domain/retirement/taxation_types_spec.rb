# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::TaxationTypes do
  describe ".for_product" do
    let(:category) { object_double Category.new, combo?: false, ident: product.category_ident }

    before do
      allow(Domain::MasterData::Categories).to receive(:get_by_ident) \
        .with(product.category_ident).and_return category
    end

    context "when pensionsfonds" do
      let(:product) { object_double Retirement::Product.new, category_ident: "ae82f6e4" }

      it { expect(described_class.for_product(product)).to eq :type1 }
    end

    context "when unterstuetzungskasse" do
      let(:product) { object_double Retirement::Product.new, category_ident: "9fa6b053" }

      it { expect(described_class.for_product(product)).to eq :type2 }
    end

    context "when direktzusage" do
      let(:product) { object_double Retirement::Product.new, category_ident: "c13f6d0c" }

      it { expect(described_class.for_product(product)).to eq :type2 }
    end

    context "when private rentenversicherung" do
      let(:product) { object_double Retirement::Product.new, category_ident: "f0a0e78c" }

      it { expect(described_class.for_product(product)).to eq :type3 }
    end

    context "when privatrente fonds" do
      let(:product) { object_double Retirement::Product.new, category_ident: "1fc11bd3" }

      it { expect(described_class.for_product(product)).to eq :type3 }
    end

    context "when kapitallebensversicherung" do
      let(:product) { object_double Retirement::Product.new, category_ident: "c187d55b" }

      it { expect(described_class.for_product(product)).to eq :type3 }
    end

    context "when riester classic" do
      let(:product) { object_double Retirement::Product.new, category_ident: "68f0b130" }

      it { expect(described_class.for_product(product)).to eq :riester }
    end

    context "when riester fonds" do
      let(:product) { object_double Retirement::Product.new, category_ident: "1fc11bd1" }

      it { expect(described_class.for_product(product)).to eq :riester }
    end

    context "when riester fonds non insurance" do
      let(:product) { object_double Retirement::Product.new, category_ident: "1fc11bd2" }

      it { expect(described_class.for_product(product)).to eq :riester }
    end

    context "when basis classic" do
      let(:product) { object_double Retirement::Product.new, category_ident: "63cfb93c" }

      it { expect(described_class.for_product(product)).to eq :basis }
    end

    context "when basis fonds" do
      let(:product) { object_double Retirement::Product.new, category_ident: "1fc11bd0" }

      it { expect(described_class.for_product(product)).to eq :basis }
    end

    context "when direktversicherung classic" do
      let(:product) do
        object_double Retirement::Product.new, category_ident: "e97a99d7", document_date: document_date
      end

      context "when document date is nil" do
        let(:document_date) { nil }

        it { expect(described_class.for_product(product)).to eq nil }
      end

      context "when document date is bigger than 01-01-2005" do
        let(:document_date) { Date.new(2005, 1, 2) }

        it { expect(described_class.for_product(product)).to eq :type1 }
      end

      context "when document date is equal 01-01-2005" do
        let(:document_date) { Date.new(2005, 1, 1) }

        it { expect(described_class.for_product(product)).to eq :type1 }
      end

      context "when document date is less than 01-01-2004" do
        let(:document_date) { Date.new(2004, 1, 1) }

        it { expect(described_class.for_product(product)).to eq :type3 }
      end
    end

    context "when direktversicherung fonds" do
      let(:product) do
        object_double Retirement::Product.new, category_ident: "1fc11bd5", document_date: document_date
      end

      context "when document date is nil" do
        let(:document_date) { nil }

        it { expect(described_class.for_product(product)).to eq nil }
      end

      context "when document date is bigger than 01-01-2005" do
        let(:document_date) { Date.new(2005, 1, 2) }

        it { expect(described_class.for_product(product)).to eq :type1 }
      end

      context "when document date is equal 01-01-2005" do
        let(:document_date) { Date.new(2005, 1, 1) }

        it { expect(described_class.for_product(product)).to eq :type1 }
      end

      context "when document date is less than 01-01-2004" do
        let(:document_date) { Date.new(2004, 1, 1) }

        it { expect(described_class.for_product(product)).to eq :type3 }
      end
    end

    context "when pensionskasse" do
      let(:product) do
        object_double Retirement::Product.new, category_ident: "cbc035f2", document_date: document_date
      end

      context "when document date is nil" do
        let(:document_date) { nil }

        it { expect(described_class.for_product(product)).to eq nil }
      end

      context "when document date is bigger than 01-01-2005" do
        let(:document_date) { Date.new(2005, 1, 2) }

        it { expect(described_class.for_product(product)).to eq :type1 }
      end

      context "when document date is equal 01-01-2005" do
        let(:document_date) { Date.new(2005, 1, 1) }

        it { expect(described_class.for_product(product)).to eq :type1 }
      end

      context "when document date is less than 01-01-2004" do
        let(:document_date) { Date.new(2004, 1, 1) }

        it { expect(described_class.for_product(product)).to eq :type3 }
      end
    end

    context "with combo category" do
      let(:product) { object_double Retirement::Product.new, category_ident: "c13f6d0c" }
      let(:category) { object_double Category.new, combo?: true, included_category_ids: %w[ID1 ID3] }

      before do
        categories = [
          object_double(Category.new, id: "ID1", ident: "SOME"),
          object_double(Category.new, id: "ID2", ident: "1fc11bd1"),
          object_double(Category.new, id: "ID3", ident: "ae82f6e4")
        ]
        allow(Domain::MasterData::Categories).to receive(:all).and_return categories
      end

      it { expect(described_class.for_product(product)).to eq :type1 }
    end
  end
end
