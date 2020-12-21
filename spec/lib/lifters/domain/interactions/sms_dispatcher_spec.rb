# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Interactions::SmsDispatcher do
  let(:user)        { create(:user) }
  let(:mandate)     { create(:mandate, user: user) }
  let(:admin)       { create(:admin) }
  let(:opportunity) { create(:opportunity, mandate: mandate) }
  let(:valid_sms_data) do
    sms_data = {}
    sms_data[:content]      = "content"
    sms_data[:mandate]      = mandate
    sms_data[:phone_number] = "015123456789"
    sms_data[:admin]        = admin
    sms_data[:topic]        = opportunity
    sms_data
  end
  let(:subject) { described_class.new(valid_sms_data) }

  before do
    allow(Rails.logger).to receive(:error)
  end

  describe "#dispatch" do
    it "will abort sending if the user does not allow mailing" do
      allow(mandate).to receive(:subscriber?).and_return(false)
      error_message = "Mandate messaging is not allowed by the mandate subscription for #{mandate.id}"
      expect(Rails.logger).to receive(:error).with(error_message)
      expect { subject.dispatch }.not_to change(Interaction::Sms, :count)
    end

    it "will abort sending if the mandate belongs to the partner" do
      mandate.owner_ident = "partner"
      error_message = "The mandate #{mandate.id} doesn't belong to Clark"
      expect(Rails.logger).to receive(:error).with(error_message)
      expect { subject.dispatch }.not_to change(Interaction::Sms, :count)
    end

    context "when invalid phone format" do
      let(:invalid_sms_data) do
        sms_data = {}
        sms_data[:content]      = "content"
        sms_data[:mandate]      = mandate
        sms_data[:phone_number] = "179827387283782"
        sms_data[:admin]        = admin
        sms_data[:topic]        = opportunity
        sms_data
      end
      let(:subject) { described_class.new(invalid_sms_data) }

      it "sends exception to Sentry and re-raises it" do
        message = "Gültigkeitsprüfung ist fehlgeschlagen: phone ist nicht gültig"
        expect(Raven).to receive(:capture_exception).with(message, extra: {mandate_id: mandate.id,
                                                                           phone: invalid_sms_data[:phone_number]})

        expect { subject.dispatch }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it "will abort sending if the phone number is a land line" do
      land_line_variations = ["06912345678", "+496912345678"]
      land_line_variations.each do |land_line_number|
        valid_sms_data[:phone_number] = land_line_number
        expect { subject.dispatch }.not_to change(Interaction::Sms, :count)
      rescue ActiveRecord::RecordInvalid
      end
    end

    it "send the sms if the phone number is a land line with the disable validation flag" do
      allow_any_instance_of(Interaction::Sms).to receive(:validates_mobile_phones?).and_return(false)

      land_line_variations = ["06912345678", "+496912345678"]
      land_line_variations.each do |land_line_number|
        valid_sms_data[:phone_number] = land_line_number
        expect { subject.dispatch( false) }.to change(Interaction.all, :count).by(1)
        expect(Interaction.last.direction).to eq(Interaction.directions[:out])
      end
    end

    it "creates an outgoing interaction" do
      subject.dispatch
      expect(Interaction.count).to eq(1)
      expect(Interaction.last.direction).to eq(Interaction.directions[:out])
    end

    it "calls the url shortener" do
      expect_any_instance_of(Platform::UrlShortener).to receive(:replace_links)
        .with(valid_sms_data[:content], mandate).and_call_original
      subject.dispatch
    end

    it "generates a delivery token" do
      expect_any_instance_of(Platform::SimpleMemoryToken).to receive(:token).and_call_original
      subject.dispatch
    end

    it "calls the sms client send_sms" do
      expect_any_instance_of(OutboundChannels::Sms).to receive(:send_sms).and_call_original
      subject.dispatch
    end

    it "assigns the generated randomized delivery token to the created interaction" do
      subject.dispatch
      expect(Interaction.last.delivery_token).not_to be_nil
    end

    context "with sms server error" do
      let(:error_message) { "error in sending" }

      before do
        allow_any_instance_of(OutboundChannels::Sms).to receive(:send_sms).and_raise(RuntimeError, error_message)
      end

      it "notifies sentry if a runtime error is raised from the sms client" do
        expect(Raven).to receive(:capture_message).with(error_message, anything)
        subject.dispatch
      end

      it "doesn't save the newly created sms in the database" do
        expect{ subject.dispatch }.not_to change(Interaction::Sms, :count)
      end
    end
  end

  describe "#dispatch_for_non_clark" do
    it "will send sms to customer not belonging to clark" do
      mandate.owner_ident = "partner"
      expect { subject.dispatch_for_non_clark }.to change(Interaction.all, :count).by(1)
      expect(Interaction.last.direction).to eq(Interaction.directions[:out])
    end
  end
end
