# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/repositories/admin_repository"

RSpec.describe Salesforce::Repositories::AdminRepository do
  subject(:repository) { described_class.new }

  let!(:bot) { create(:admin) }

  describe "#bot" do
    it "returns bot" do
      admin = repository.bot
      expect(admin).to be_kind_of Admin
      expect(admin.id).to eq(bot.id)
    end
  end
end
