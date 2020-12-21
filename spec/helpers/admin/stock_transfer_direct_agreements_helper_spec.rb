# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::StockTransferDirectAgreementsHelper, type: :helper do
  context "when trying to reference the entity causing the error" do
    let(:sample_message) { "sample message #{rand}" }
    let(:error) { StandardError.new(sample_message) }
    let(:namespace) { "/de/admin" }

    it "should humanize the key, if it isn't an entity" do
      fatal_key = helper.render_error_cause(key: :fatal, error: error, namespace: namespace)
      expect(fatal_key).to eq("#{:fatal.to_s.humanize}: '#{sample_message}'")
      funny_key = helper.render_error_cause(key: :funny, error: error, namespace: namespace)
      expect(funny_key).to eq("#{:funny.to_s.humanize}: '#{sample_message}'")
    end

    it "should not fail, if the error is empty" do
      rendered = helper.render_error_cause(key: :funny, error: nil, namespace: namespace)
      expect(rendered).to eq("#{:funny.to_s.humanize}: ''")
    end

    [Inquiry, Mandate].each do |supported_model|
      it "should link to the #{supported_model.name.downcase} passed in" do
        entity = build_stubbed(supported_model.name.downcase.to_sym)
        link_text = "#{supported_model.name.humanize}: '#{sample_message}'"
        link_config = [namespace, entity]
        expect(helper).to receive(:link_to).with(link_text, link_config)
        helper.render_error_cause(key: entity, error: error, namespace: namespace)
      end
    end
  end
end
