# frozen_string_literal: true

require "rails_helper"

RSpec.describe OutboundChannels::Messenger::TransactionalMessenger do
  describe "#send_message" do
    let(:content_key) { "sample_message" }
    let!(:admin) { find_or_create_first_admin }

    context "The mandate belongs to Clark" do
      let(:mandate)      { create(:mandate) }
      let(:with_options) { {name: "Fabs", mandate_id: mandate.id} }
      let(:subject)      { described_class.new(mandate, content_key, with_options) }

      it "passes the message to the relay" do
        expect(OutboundChannels::Messenger::MessageRelay).to receive(:pass_message)
        subject.send_message
      end

      context "when returning a message" do
        let(:message) { subject.send_message }

        it "has the correct attributes" do
          expect(message.content).to eq("Hallo Fabs\n")
          expect(message.mandate).to eq(mandate)
          expect(message.admin).to eq(admin)
          expect(message.direction).to eq("out")
          expect(message.created_by_robo).to eq(true)
          expect(message.cta_text).to eq("Zu meiner #{mandate.id}")
          expect(message.cta_link).to eq("/app/mandate/#{mandate.id}")
          expect(message.cta_section).to eq("manager")
        end

        context "when push attributes are available" do
          let(:push) { message.metadata["push_data"] }

          it "has the correct attributes" do
            expect(push["title"]).to eq("Clark")
            expect(push["content"]).to eq("Wichtiges Update zu deinem Vertrag!")
          end
        end
      end

      context "when fallback push is disabled" do
        it "passes the message to the relay with push set to false" do
          expect(OutboundChannels::Messenger::MessageRelay).to receive(:pass_message) do |_arg1, arg2|
            expect(arg2).to be_kind_of(Config::Options)
            expect(arg2[:push_with_sms_fallback]).to eq false
          end
          subject.send_message(push_sms_fallback: false)
        end
      end
    end

    context "when the mandate belongs to the partner" do
      it "returns a nil message" do
        mandate      = create(:mandate, owner_ident: "partner")
        with_options = {name: "Fabs", mandate_id: mandate.id}
        message = described_class.new(mandate, content_key, with_options).send_message

        expect(message).to be_nil
      end
    end

    context "when the mandate belongs to active partner" do
      let!(:partner) { create(:partner, :active) }

      it "sends the message" do
        mandate      = create(:mandate, owner_ident: partner.ident)
        with_options = {name: "Fabs", mandate_id: mandate.id}
        message = described_class.new(mandate, content_key, with_options).send_message

        expect(message).not_to be_nil
      end
    end
  end
end
