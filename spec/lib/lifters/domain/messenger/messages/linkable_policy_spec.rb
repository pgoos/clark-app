# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::Messages::LinkablePolicy do
  describe "#authorized?" do
    subject { described_class.new mandate }

    let(:mandate) { build_stubbed :mandate }

    context "when linkable type is not supported" do
      it "returns false" do
        linkable = InquiryCategory.new
        expect(subject.authorized?(linkable)).to eq false
      end
    end

    context "when linkable is a mandate data" do
      let(:cockpit) { instance_double Domain::ContractOverview::Cockpit }

      before do
        allow(Domain::ContractOverview::Cockpit).to receive(:new).with(mandate).and_return cockpit
      end

      shared_examples "cockpit linkable" do |linkable_class|
        context "when linkable is #{linkable_class.name}" do
          let(:cockpit_collection) do
            [
              linkable_class.new(id: 1),
              linkable_class.new(id: 2)
            ]
          end

          before do
            allow(cockpit).to receive(linkable_class.name.tableize.to_sym).and_return cockpit_collection
          end

          it "checks whether an entity present in mandate's cockpit" do
            expect(subject.authorized?(cockpit_collection[0])).to eq true
            expect(subject.authorized?(cockpit_collection[1])).to eq true

            unrelated = linkable_class.new(id: 3)
            expect(subject.authorized?(unrelated)).to eq false
          end
        end
      end

      include_examples "cockpit linkable", Product
      include_examples "cockpit linkable", InquiryCategory
      include_examples "cockpit linkable", Recommendation
      include_examples "cockpit linkable", Offer
    end

    context "when linkable is Questionnaire" do
      context "when it's active" do
        it "returns true" do
          questionnaire = build :questionnaire
          allow(questionnaire).to receive(:active?).and_return true
          expect(subject.authorized?(questionnaire)).to eq true
        end
      end

      context "when it's not active" do
        it "returns false" do
          questionnaire = build :questionnaire
          allow(questionnaire).to receive(:active?).and_return false
          expect(subject.authorized?(questionnaire)).to eq false
        end
      end
    end
  end
end
