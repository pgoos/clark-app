# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::OfferAutomationHelper do
  subject {
    object = Object.new
    object.extend described_class
    object
  }

  describe "when it renders relative paths for a different environment than development" do
    let(:seed1) { rand(10) }
    let(:seed2) { rand(10) }
    let(:offer_rule_matrix_css) { "@clarksource/offer-rule-matrix-fe71ced52b3b88c3b65972ccb9565b#{seed1}#{seed2}.css" }
    let(:offer_rule_matrix_js) { "@clarksource/offer-rule-matrix-70a35869bd61611b6c8dbcd64dec0b#{seed1}#{seed2}.js" }
    let(:vendor_css) { "vendor-5170e8d2134c15ed1b951bb314fa9b#{seed1}#{seed2}.css" }
    let(:vendor_js) { "vendor-24aeb66a6fc7b543f507342e08260f#{seed1}#{seed2}.js" }

    before do
      allow(Rails).to receive_message_chain(:env, :development?).and_return(false)

      asset_map = <<~JSON
        {
          "assets": {
            "assets/@clarksource/offer-rule-matrix.css": "assets/#{offer_rule_matrix_css}",
            "assets/@clarksource/offer-rule-matrix.js": "assets/#{offer_rule_matrix_js}",
            "assets/vendor.css": "assets/#{vendor_css}",
            "assets/vendor.js": "assets/#{vendor_js}"
          }
        }
      JSON

      path = Rails.root.join("public", "assets", "client-ops", "@clarksource/offer-rule-matrix", "assets", "assetMap.json")
      allow(File).to receive(:read).with(path).and_return(asset_map)
    end

    it "should render the vendor dev css path" do
      expect(subject.client_ops_vendor_css_path).to eq("/assets/client-ops/@clarksource/offer-rule-matrix/assets/#{vendor_css}")
    end

    it "should render the vendor dev js path" do
      expect(subject.client_ops_vendor_js_path).to eq("/assets/client-ops/@clarksource/offer-rule-matrix/assets/#{vendor_js}")
    end

    it "should render the app dev css path" do
      expect(subject.client_ops_app_css_path)
        .to eq("/assets/client-ops/@clarksource/offer-rule-matrix/assets/#{offer_rule_matrix_css}")
    end

    it "should render the app dev js path" do
      expect(subject.client_ops_app_js_path)
        .to eq("/assets/client-ops/@clarksource/offer-rule-matrix/assets/#{offer_rule_matrix_js}")
    end
  end

  describe "when it renders relative paths for development" do
    before do
      allow(Rails).to receive_message_chain(:env, :development?).and_return(true)
    end

    it "should render the vendor dev css path" do
      expect(subject.client_ops_vendor_css_path).to eq("/assets/client-ops/offer-rule-matrix/assets/vendor-dev.css")
    end

    it "should render the vendor dev js path" do
      expect(subject.client_ops_vendor_js_path).to eq("/assets/client-ops/offer-rule-matrix/assets/vendor-dev.js")
    end

    it "should render the app dev css path" do
      expect(subject.client_ops_app_css_path)
        .to eq("/assets/client-ops/offer-rule-matrix/assets/@clarksource/offer-rule-matrix-dev.css")
    end

    it "should render the app dev js path" do
      expect(subject.client_ops_app_js_path)
        .to eq("/assets/client-ops/offer-rule-matrix/assets/@clarksource/offer-rule-matrix-dev.js")
    end
  end
end
