# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationMailer do
  context "mail headers" do
    let(:built_headers) { described_class.new.send(:build_mail_headers, document_type, model) }
    let(:positive_integer) { (rand(100).floor + 1) }
    let(:document_type) { instance_double(DocumentType, id: positive_integer) }
    let(:model_id) { positive_integer + 1 }
    let(:model) { FactoryBot.build_stubbed(:mandate, id: model_id) }

    it "sets the X-Document-Type-ID" do
      expect(built_headers["X-Document-Type-ID"]).to eq(positive_integer)
    end

    it "defaults X-MC-PreserveRecipients to true" do
      expect(built_headers["X-MC-PreserveRecipients"]).to eq("true")
    end

    it "optionally sets X-MC-PreserveRecipients to false" do
      built = described_class.new.send(:build_mail_headers, document_type, model, "false")
      expect(built["X-MC-PreserveRecipients"]).to eq("false")

      # TODO: exclude illegal values for X-MC-PreserveRecipients
    end

    it "sets X-MC-Tags for the document type" do
      expect(built_headers["X-MC-Tags"]).to eq("document_type_#{positive_integer}")
    end

    it "sets the X-Documentable-ID for a model" do
      expect(built_headers["X-Documentable-ID"]).to eq(model_id)
    end

    it "sets the X-Documentable-Type for a model" do
      expect(built_headers["X-Documentable-Type"]).to eq(model.class.name)
    end
  end

  describe "#dispatch_mail" do
    let(:mandate) { build :mandate, user: user, state: :created }
    let(:user) { build :user, email: email, subscriber: true }
    let(:email) { "test@gmail.com" }
    let(:document_type) { instance_double(DocumentType, id: 1, key: "test") }
    let(:mailer) { double(ApplicationMailer, deliver_now: true) }

    let(:subject) do
      described_class.new.send(
        :dispatch_mail,
        mandate: mandate,
        document_type: document_type,
        template: nil,
        documentable: mandate,
        check_mail_allowed: false,
        check_interaction_allowed: false
      ) { mailer.deliver_now }
    end

    context "disabled emails" do
      before do
        allow(Settings)
          .to receive_message_chain(:message_only_feature_switch, :disabled_emails, :document_type_keys)
          .and_return([document_type.key])
      end

      context "when message_only feature switch is on" do
        before { allow(Features).to receive(:active?).with(Features::MESSAGE_ONLY).and_return(true) }

        it "stops sending the blacklisted emails" do
          expect(mailer).not_to receive(:deliver_now)
          expect(subject).to eq(nil)
        end
      end
    end

    context "when message_only feature switch is off" do
      before { allow(Features).to receive(:active?).with(Features::MESSAGE_ONLY).and_return(false) }

      it "doesn't stop sending the blacklisted emails" do
        expect(mailer).to receive(:deliver_now)
        expect(subject).to eq(true)
      end
    end
  end
end
