# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/repositories/category_repository"

RSpec.describe Contracts::Repositories::CategoryRepository, :integration do
  describe "#active_umbrella_categories" do
    subject { described_class.new.active_umbrella_categories }

    let!(:categories) do
      [
        create(:category, :umbrella, :active),
        create(:category, :regular, :active),
        create(:category, :umbrella, :inactive)
      ]
    end

    it "returns categories" do
      expect(subject.count).to eq 1
      category = subject.first
      expect(category.ident).to eq categories[0].ident
      expect(category.name).to eq categories[0].name
      expect(category.vertical_ident).to eq categories[0].vertical.ident
    end
  end
end
