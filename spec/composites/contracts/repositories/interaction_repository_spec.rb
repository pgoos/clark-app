# frozen_string_literal: true

require "rails_helper"
require "composites/contracts/repositories/interaction_repository"

RSpec.describe Contracts::Repositories::InteractionRepository, :integration do
  let(:admin) { create(:admin) }
  let(:product) { create(:product) }
  let(:repo) { described_class.new }
  let(:attributes) do
    {
      customer_id: product.mandate_id,
      admin_id: admin.id,
      content: "Rückfrage zu deinem Vertrag",
      metadata: { title: "no product can be created" },
      contract_id: product.id
    }
  end

  describe "#register_sent_email!" do
    it "adds a new interaction to database" do
      repo.register_sent_email!(attributes)

      expect(Interaction::Email.count).to be 1
    end
  end
end
