# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Consultants::ConsultantsRepository do
  subject { described_class.new }

  describe "#default_consultant" do
    let(:consultant_email) { "consultant@exmaple.com" }

    context "when there is a setting" do
      before do
        allow(Settings).to receive_message_chain("category_consultants.default")
          .and_return(consultant_email)
      end

      context "when a consultant exists" do
        let!(:default_consultant) { create(:admin, email: consultant_email) }

        it "returns the consultant" do
          expect(subject.default_consultant).to eq(default_consultant)
        end
      end

      context "when a consultant doesn't exist" do
        let!(:another_consultant) do
          create(:admin, email: "another_consultant@exmaple.com")
        end

        it "returns nil" do
          expect(subject.default_consultant).to be_nil
        end
      end
    end

    context "when there isn't a setting" do
      let!(:another_consultant) do
        create(:admin, email: "another_consultant@exmaple.com")
      end

      it "returns nil" do
        expect(subject.default_consultant).to be_nil
      end
    end
  end

  describe "#last_consultant" do
    let!(:first_consultant) { create(:admin, email: "first@example.com") }
    let!(:last_consultant) { create(:admin, email: "last@example.com") }

    it "returns the last consultant" do
      expect(subject.last_consultant).to eq(last_consultant)
    end
  end
end
