# frozen_string_literal: true

require "rails_helper"

RSpec.describe InquiryCategoryMailerHelper, type: :helper do
  describe "#mc_possible_reasons" do
    context "when possible reasons is given" do
      it "returns correct render" do
        @possible_reasons = [:payment_method]
        expect(mc_possible_reasons)
          .to include(I18n.t("admin.inquiry_categories.feedback_form.reasons.payment_method"))
      end
    end

    context "when possible reasons is nil" do
      it "returns nil" do
        @possible_reasons = nil
        expect(mc_possible_reasons).to be_nil
      end
    end

    context "when possible reasons is empty" do
      it "returns nil" do
        @possible_reasons = []
        expect(mc_possible_reasons).to be_nil
      end
    end
  end
end
