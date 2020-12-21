# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::Helpers::MandateHelpers, :integration do
  class MandateHelpersDummy
    include ClarkAPI::Helpers::MandateHelpers

    attr_reader :err_hash, :status

    def error!(err_hash, status)
      @err_hash = err_hash
      @status = status
    end

    def assert_no_error_response_created
      return if @err_hash.blank? && @status.blank?
      raise("Error response created! @err_hash: '#{@err_hash.inspect}', @status: '#{@status}'")
    end
  end

  subject { MandateHelpersDummy.new }

  let(:mandate) { instance_double(Mandate) }

  context "errors with iban in the error message" do
    let(:iban) { "DE12 5001 0517 0648 4898 00" }
    let(:sane_iban) { "----removed-possible-iban----" }

    let(:iban_other_country) { "XY12 5001 0517 0648 4898 90" }
    let(:sane_iban_other_country) { "----removed-possible-iban----" }

    let(:iban_in_text) { "asdf DE12 5001 0517 0648 4898 90 asdf" }
    let(:sane_iban_in_text) { "asdf ----removed-possible-iban----asdf" }

    let(:iban_no_whitespace_inside) { "DE12500105170648489890" }
    let(:sane_iban_no_whitespace_inside) { "----removed-possible-iban----" }

    let(:iban_no_leading_whitespace) { "iban:DE12 5001 0517 0648 4898 90" }
    let(:sane_iban_no_leading_whitespace) { "iban:----removed-possible-iban----" }

    let(:iban_no_trailing_whitespace) { "DE12 5001 0517 0648 4898 90!" }
    let(:sane_iban_no_trailing_whitespace) { "----removed-possible-iban----!" }

    let(:known_iban_message) { "Unexpected byte '58' in IBAN code ':DE12 5001 0517 0648 4898 90'" }
    let(:sane_iban_message) { "Unexpected byte '58' in IBAN code ':----removed-possible-iban----'" }

    def expect_sane_error_message(message, sane_message)
      allow(mandate).to receive(:update_attributes).with(any_args).and_raise(message)

      expect(Raven)
        .to receive(:capture_message)
        .with(
          sane_message,
          extra: an_instance_of(Hash)
        )

      subject.mandate_update_attributes(mandate, {})

      expect(subject.err_hash).to eq(error: sane_message)
      expect(subject.status).to eq(500)
    end

    it "raises an error with a plain iban" do
      expect_sane_error_message(iban, sane_iban)
    end

    it "raises an error with a plain iban of a different country" do
      expect_sane_error_message(iban_other_country, sane_iban_other_country)
    end

    it "raises an error with a iban within a text" do
      expect_sane_error_message(iban_in_text, sane_iban_in_text)
    end

    it "raises an error with a iban without white space" do
      expect_sane_error_message(iban_no_whitespace_inside, sane_iban_no_whitespace_inside)
    end

    it "raises an error with a iban without leading white space" do
      expect_sane_error_message(iban_no_leading_whitespace, sane_iban_no_leading_whitespace)
    end

    it "raises an error with a iban without trailing white space" do
      expect_sane_error_message(iban_no_trailing_whitespace, sane_iban_no_trailing_whitespace)
    end

    context "handles known iban exception as validation failure" do
      before do
        allow(mandate).to receive(:update_attributes).with(any_args).and_raise(known_iban_message)
        allow(mandate).to receive(:iban=).with("setting of iban failed")
        allow(mandate).to receive(:valid?)
        allow(Raven)
          .to receive(:capture_message)
          .with(
            sane_iban_message,
            extra: an_instance_of(Hash)
          )
      end

      it "resets the iban to an invalid value and validates the object" do
        expect(mandate).to receive(:iban=).with("setting of iban failed").ordered
        expect(mandate).to receive(:valid?).ordered

        subject.mandate_update_attributes(mandate, {})
      end

      it "sends the Raven anyway" do
        expect(Raven)
          .to receive(:capture_message)
          .with(
            sane_iban_message,
            extra: an_instance_of(Hash)
          )

        subject.mandate_update_attributes(mandate, {})
      end

      it "does not fail with an api 500 status error" do
        subject.mandate_update_attributes(mandate, {})

        subject.assert_no_error_response_created
      end
    end
  end

  context "update success" do
    let(:attributes) { instance_double(Hash) }

    it "should return true" do
      allow(mandate).to receive(:update_attributes).with(attributes).and_return(true)
      expect(subject.mandate_update_attributes(mandate, attributes)).to eq(true)
    end

    it "should not call error! in case of success" do
      allow(mandate).to receive(:update_attributes).with(attributes).and_return(true)
      subject.mandate_update_attributes(mandate, attributes)
      subject.assert_no_error_response_created
    end

    it "should return false if mandate.update_attributes returns false" do
      allow(mandate).to receive(:update_attributes).with(attributes).and_return(false)
      expect(subject.mandate_update_attributes(mandate, attributes)).to eq(false)
    end

    it "should not call error! in case of validation failure" do
      allow(mandate).to receive(:update_attributes).with(attributes).and_return(false)
      subject.mandate_update_attributes(mandate, attributes)
      subject.assert_no_error_response_created
    end
  end

  context "whitelabel" do
    let(:mandate)    { create(:mandate) }
    let(:attributes) { {iban: "some IBAN value"} }

    before do
      allow(Settings.clark_api.update_mandate).to receive(:iban_required).and_return(true)
    end

    after do
      allow(Core::Context).to receive(:running).and_call_original
    end

    it "calls update method and return false (not valid record) if params include only IBAN" do
      expect(subject.mandate_update_attributes(mandate, attributes)).to be_falsy
    end

    it "returns method_not_allowed if not only IBAN needs to be updated" do
      expect(subject.mandate_update_attributes(mandate, attributes.merge(first_name: "Clark")))
        .to eq(405)
    end
  end
end
