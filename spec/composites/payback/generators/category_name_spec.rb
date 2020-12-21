# frozen_string_literal: true

require "rails_helper"
require "composites/payback/generators/category_name"

RSpec.describe Payback::Generators::CategoryName do
  subject(:generated_category_name) { described_class.call(category_name, company_name) }

  let(:max_characters) { Payback::Generators::CategoryName::MAX_CHARACTERS }
  let(:category_name) { Faker::Lorem.characters(number: 17) }
  let(:company_name) { Faker::Lorem.characters(number: 8) }

  context "when two names doesn't exceed max length" do
    let(:expected_name) { "#{category_name}/#{company_name}" }

    it "generates expected name" do
      expect(generated_category_name).to eq(expected_name)
    end

    it "generated name length should not be more than maximum allowed chars" do
      expect(generated_category_name.length).to be <= max_characters
    end
  end

  context "when category name length is more than allowed" do
    let(:first_word) { Faker::Lorem.characters(number: 7) }
    let(:second_word) { Faker::Lorem.characters(number: 11) }
    let(:third_word) { Faker::Lorem.characters }
    let(:category_name) { "#{first_word} #{second_word} #{third_word}" }
    let(:expected_name) do
      "#{first_word} #{second_word} #{third_word.first.upcase}/#{company_name}"
    end

    it "generates expected name" do
      expect(generated_category_name).to eq(expected_name)
    end

    it "generated name length should not be more than maximum allowed chars" do
      expect(generated_category_name.length).to be <= max_characters
    end
  end

  context "when category name length is more than allowed but the company name is to short" do
    let(:first_word) { Faker::Lorem.characters(number: 7) }
    let(:second_word) { Faker::Lorem.characters(number: 10) }
    let(:third_word) { Faker::Lorem.characters(number: 5) }
    let(:company_name) { Faker::Lorem.characters(number: 3) }
    let(:category_name) { "#{first_word} #{second_word} #{third_word}" }
    let(:expected_name) { "#{category_name}/#{company_name}" }

    it "generates expected name containing all the category name" do
      expect(generated_category_name).to eq(expected_name)
    end

    it "generated name length should not be more than maximum allowed chars" do
      expect(generated_category_name.length).to be <= max_characters
    end
  end

  context "when both names length is more than allowed" do
    let(:first_word) { Faker::Lorem.characters(number: 10) }
    let(:second_word) { Faker::Lorem.characters(number: 8) }
    let(:third_word) { Faker::Lorem.characters(number: 5) }
    let(:fourth_word) { Faker::Lorem.characters }
    let(:fifth_word) { Faker::Lorem.characters(number: 5) }
    let(:category_name) { "#{first_word}-#{second_word} #{third_word} & #{fourth_word}" }
    let(:company_name) { "#{fifth_word}-#{third_word} #{first_word}" }

    let(:expected_name) do
      "#{first_word} #{second_word.truncate(7)} #{third_word.first.upcase}#{fourth_word.first.upcase}" \
      "/#{fifth_word} #{third_word.first.upcase}#{first_word.first.upcase}"
    end

    it "generates expected name" do
      expect(generated_category_name).to eq(expected_name)
    end

    it "generated name length should not be more than maximum allowed chars" do
      expect(generated_category_name.length).to be <= max_characters
    end
  end

  context "when company name length is more than allowed but the category name is to short" do
    let(:first_word) { Faker::Lorem.characters(number: 8) }
    let(:second_word) { Faker::Lorem.characters(number: 15) }
    let(:third_word) { Faker::Lorem.characters(number: 6) }
    let(:fourth_word) { Faker::Lorem.characters }
    let(:category_name) { Faker::Lorem.characters(number: 7) }
    let(:company_name) { "#{first_word}/#{second_word} #{third_word} / #{fourth_word}" }
    let(:expected_name) do
      "#{category_name}/#{first_word} #{second_word.truncate(10)} #{third_word.first.upcase}#{fourth_word.first.upcase}"
    end

    it "generates expected name containing all the category name" do
      expect(generated_category_name).to eq(expected_name)
    end

    it "generated name length should not be more than maximum allowed chars" do
      expect(generated_category_name.length).to be <= max_characters
    end
  end

  context "when first word on name is to long" do
    let(:first_word) { Faker::Lorem.characters(number: 25) }
    let(:second_word) { Faker::Lorem.characters(number: 10) }
    let(:category_name) { "#{first_word}/#{second_word}" }
    let(:company_name) { Faker::Lorem.characters(number: 20) }
    let(:expected_name) do
      "#{first_word.truncate(18)} #{second_word.first.upcase}/#{company_name.truncate(9)}"
    end

    it "generates expected name containing all the category name" do
      expect(generated_category_name).to eq(expected_name)
    end

    it "generated name length should not be more than maximum allowed chars" do
      expect(generated_category_name.length).to be <= max_characters
    end
  end
end
