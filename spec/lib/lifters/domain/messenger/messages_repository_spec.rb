# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::MessagesRepository, :integration do
  subject(:repo) { described_class.new }

  describe "#all" do
    let(:mandate) { create :mandate }

    it "returns messages belonging to mandate" do
      message1 = create :interaction_message, mandate: mandate
      create :interaction_message, :with_mandate

      expect(repo.all(mandate)).to be_kind_of Array
      expect(repo.all(mandate)).to eq [message1]
    end

    it "orders messages by creation date" do
      message1 = create :interaction_message, mandate: mandate, created_at: 2.days.ago
      message2 = create :interaction_message, mandate: mandate, created_at: 1.day.ago

      expect(repo.all(mandate)).to eq [message2, message1]
    end

    context "with pagination params" do
      context "with limit" do
        it "returns collection with size not greater than given parameter" do
          create :interaction_message, mandate: mandate
          create :interaction_message, mandate: mandate

          expect(repo.all(mandate, limit: 1).size).to eq 1
        end
      end

      context "with before_id/after_id" do
        it "returns collection in given range" do
          message1 = create :interaction_message, mandate: mandate
          message2 = create :interaction_message, mandate: mandate
          message3 = create :interaction_message, mandate: mandate
          message4 = create :interaction_message, mandate: mandate

          expect(repo.all(mandate, before_id: message3.id)).to \
            match_array [message1, message2]

          expect(repo.all(mandate, after_id: message2.id)).to \
            match_array [message3, message4]

          expect(repo.all(mandate, before_id: message4.id, after_id: message1.id)).to \
            match_array [message2, message3]
        end
      end
    end
  end
end
