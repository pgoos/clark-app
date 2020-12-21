# frozen_string_literal: true

require "rails_helper"

describe SendMultipleMessageJob, type: :job do
  describe ".perform" do
    let!(:mandate1) { create(:mandate) }
    let!(:mandate2) { create(:mandate) }
    let!(:admin) { create(:admin) }
    let(:type) { "messenger.instant_advice_ranges_changed" }
    let(:content) { I18n.t("#{type}.content") }

    context "if number of IDs is less than 500" do
      before { allow(Features).to receive(:active?).with(Features::MESSENGER).and_return true }

      it "creates Interaction::Message" do
        expect { subject.perform([mandate1.id, mandate2.id], type) }
          .to change(Interaction::Message, :count).by(2)
      end
    end

    context "if number of passed IDs exceed 500" do
      let(:ids) { Array.new(501) { rand(500) } }

      it "raise error" do
        expect { subject.perform(ids, type) }
          .to raise_error(StandardError, "Too many IDs were passed, the max number is 500")
      end
    end
  end
end
