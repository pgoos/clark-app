# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Finance::PaymentImporter::Repositories::ProductRepository do
  let(:products) { create_list(:product, 3) }

  it "includes NameMatcher module" do
    expect(described_class.included_modules).to include(FondsFinanz::NameMatcher)
  end

  it "return all product match passed numbers" do
    query_products = products[0..1]
    query_numbers = query_products.map(&:number)
    expect(described_class.new.products(query_numbers)).to eq(query_products.group_by(&:number))
  end

  context "#find_match" do
    def create_record(first_name, last_name, number)
      OpenStruct.new(first_name: first_name, last_name: last_name, number: number)
    end

    def create_repo_object(numbers)
      obj = described_class.new
      obj.products(numbers)
      obj
    end

    before do
      repository_object.products(products.map(&:number))
    end

    let(:repository_object) { described_class.new }
    let(:test_product) { products.sample }
    let(:exception_module) { Domain::Finance::PaymentImporter::FondsFinanz::Exceptions }

    it "return matched product" do
      record = create_record(test_product.mandate.first_name, test_product.mandate.last_name, test_product.number)
      matched_product = repository_object.find_match(record)
      expect(matched_product).to eq(test_product)
    end

    it "raise FirstNameInFileNotFound when record first_name is blank" do
      record = create_record(nil, test_product.mandate.last_name, test_product.number)
      expect { repository_object.find_match(record) }.to raise_error(exception_module::FirstNameInFileNotFound)
    end

    it "raise LastNameInFileNotFound when record last_name is blank" do
      record = create_record(test_product.mandate.first_name, nil, test_product.number)
      expect { repository_object.find_match(record) }.to raise_error(exception_module::LastNameInFileNotFound)
    end

    it "raise ProductNumberNotFound when product not found" do
      record = create_record(test_product.mandate.first_name, test_product.mandate.last_name, -1)
      expect { repository_object.find_match(record) }.to raise_error(exception_module::ProductNumberNotFound)
    end

    it "raise MandateNotFound when product mandate is blank" do
      bad_product = create(:product, mandate: nil)
      test_repo = create_repo_object(bad_product.number)
      record = create_record("something", "something", bad_product.number)
      expect { test_repo.find_match(record) }.to raise_error(exception_module::MandateNotFound)
    end

    context "raise MandateNameNotMatch" do
      def it_raise_error(record, product)
        test_repo = create_repo_object(product.number)
        expect { test_repo.find_match(record) }.to raise_error(exception_module::MandateNameNotMatch)
      end

      it "raise when mandate first name is blank" do
        mandate = create(:mandate, first_name: nil)
        bad_product = create(:product, mandate: mandate)
        record = create_record("Something", bad_product.mandate.last_name, bad_product.number)
        it_raise_error(record, bad_product)
      end

      it "raise when mandate last name is blank" do
        mandate = create(:mandate, last_name: nil)
        bad_product = create(:product, mandate: mandate)
        record = create_record(bad_product.mandate.first_name, "Something", bad_product.number)
        it_raise_error(record, bad_product)
      end

      it "raise when mandate name does NOT match record name" do
        product = create(:product)
        record = create_record("Something", "Something", product.number)
        it_raise_error(record, product)
      end
    end

    it "match names with NameMatcher" do
      record = create_record(test_product.mandate.first_name, test_product.mandate.last_name, test_product.number)
      expect(repository_object).to receive(:same_name?).with(test_product.mandate, record)
      expect { repository_object.find_match(record) }.to raise_error(exception_module::MandateNameNotMatch)
    end
  end
end
