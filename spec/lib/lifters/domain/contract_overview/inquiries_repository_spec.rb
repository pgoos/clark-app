# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::ContractOverview::InquiriesRepository do
  subject(:repo) { described_class.new }

  let(:mandate)  { build :mandate, inquiries: [inquiry] }
  let(:inquiry)  { build :inquiry, :shallow, :pending }
  let(:products) { [] }

  it "returns decorated collection" do
    expect(described_class.new.all(mandate)).to all(be_kind_of(Domain::ContractOverview::Inquiry))
  end

  context "when inquiry is in state in_creation" do
    let(:inquiry) { build :inquiry, :shallow, :in_creation }

    it "includes inquery" do
      expect(repo.all(mandate, products)).to include inquiry
    end
  end

  context "when inquiry is in state pending" do
    let(:inquiry) { build :inquiry, :shallow, :pending }

    it "includes an inquery" do
      expect(repo.all(mandate, products)).to include inquiry
    end
  end

  context "when inquiry is in state contacted" do
    let(:inquiry) { build :inquiry, :shallow, :contacted }

    it "includes an inquery" do
      expect(repo.all(mandate, products)).to include inquiry
    end
  end

  context "when inquiry is in state canceled" do
    let(:inquiry) { build :inquiry, :shallow, :cancelled }

    context "without inquiry categories" do
      it "does not include an inquery" do
        expect(repo.all(mandate, products)).not_to include inquiry
      end
    end

    context "with inquiry categories" do
      it "includes an inquery" do
        inquiry.inquiry_categories = [build(:inquiry_category, :shallow)]
        expect(repo.all(mandate, products)).to include inquiry
      end
    end
  end

  context "when inquiry is in state completed" do
    let(:inquiry) { build :inquiry, :shallow, :completed }

    it "does not include inquery" do
      expect(repo.all(mandate, products)).not_to include inquiry
    end
  end

  context "with inquiry categories" do
    subject(:repo) { described_class.new(inquiry_categories_repo: inquiry_categories_repo) }

    let(:inquiry) { build :inquiry, :shallow, :pending, id: 1, inquiry_categories: inquiry_categories }

    let(:inquiry_categories) { [inquiry_category1, inquiry_category2] }
    let(:inquiry_category1) { build :inquiry_category, :shallow }
    let(:inquiry_category2) { build :inquiry_category, :shallow }

    let(:products) { [product1, product2] }
    let(:product1) { build_stubbed :product, inquiry_id: 1 }
    let(:product2) { build_stubbed :product, inquiry_id: 2 }

    let(:inquiry_categories_repo) do
      object_double(
        Domain::ContractOverview::InquiryCategoriesRepository.new
      )
    end

    it "filters out inquiry categories" do
      expect(inquiry_categories_repo).to \
        receive(:all)
        .with(kind_of(Domain::ContractOverview::Inquiry), [product1])
        .and_return([inquiry_category2])

      decorated_inquiry = repo.all(mandate, products).find { |i| i.id == inquiry.id }

      expect(decorated_inquiry).to be_present
      expect(decorated_inquiry.inquiry_categories).to eq [inquiry_category2]
    end

    context "when all categories are filtered out" do
      let(:inquiry_categories_repo) do
        object_double(
          Domain::ContractOverview::InquiryCategoriesRepository.new, all: []
        )
      end

      context "when inquiry is cancelled" do
        let(:inquiry) { build :inquiry, :shallow, :cancelled, inquiry_categories: inquiry_categories }

        it "does not include inquiry" do
          expect(repo.all(mandate, products)).not_to include inquiry
        end
      end

      context "when inquiry is not cancelled" do
        it "includes inquiry" do
          expect(repo.all(mandate, products)).to include inquiry
        end
      end
    end
  end
end
