# frozen_string_literal: true

require "rails_helper"
RSpec.describe Domain::Interactions::SmsResponder do
  let(:phone_number) { "+4915123456789" }
  let(:mandate)      { create(:mandate, phone: phone_number) }
  let!(:user)        { create(:user, mandate: mandate) }
  let(:admin)        { create(:admin) }
  let(:valid_sms_response) do
    sms_data                       = {}
    sms_data["senderAddress"]      = "4915123456789"
    sms_data["textMessageContent"] = "content"
    sms_data
  end
  let(:subject) { described_class.new(valid_sms_response) }

  describe "#build_incoming_interaction" do
    context "with only one origin sms" do
      let(:opportunity)   { create(:opportunity, mandate: mandate) }
      let!(:outgoing_sms) do
        create(:interaction_sms, mandate: mandate, admin: admin, topic: opportunity,
                                 phone_number: phone_number)
      end

      it "builds an incoming sms interaction with the same topic and mandate as origin " \
         "outgoing sms when origin sms is on an open opportunity" do
        incoming_sms = subject.build_incoming_interaction
        expect(incoming_sms).to be_a(Interaction::Sms)
        expect(incoming_sms.topic).to eq(opportunity)
        expect(incoming_sms.mandate).to eq(mandate)
        expect(incoming_sms.direction).to eq(Interaction.directions[:in])
      end

      it "builds an incoming sms interaction with the topic as origin sms even " \
         "if it was non open opportunity" do
        opportunity.state = :lost
        opportunity.save!
        incoming_sms = subject.build_incoming_interaction
        expect(incoming_sms.topic).to eq(opportunity)
      end
    end

    context "with multiple origin sms" do
      let(:opportunity) { create(:opportunity, mandate: mandate, state: :initiation_phase) }

      let(:second_opportunity) do
        create(:opportunity, mandate: mandate, state: :initiation_phase)
      end

      let!(:outgoing_sms) do
        create(:interaction_sms, mandate: mandate, admin: admin, topic: opportunity,
                                 phone_number: phone_number)
      end

      let!(:second_outgoing_sms) do
        create(:interaction_sms, mandate: mandate, admin: admin, topic: second_opportunity,
                                 phone_number: phone_number)
      end

      it "falls back to mandate as the topic for incoming sms " \
         "if multiple origin sms found on open opportunities" do
        incoming_sms = subject.build_incoming_interaction
        expect(incoming_sms.topic).to eq(mandate)
      end

      it "picks only the origin sms on an open opportunity and " \
         "map the new incoming to the same topic of the origin" do
        second_opportunity.state = :lost
        second_opportunity.save!
        incoming_sms = subject.build_incoming_interaction
        expect(incoming_sms.topic).to eq(opportunity)
      end
    end

    context "with no origin sms" do
      it "falls back to mandate as the topic for incoming sms" do
        incoming_sms = subject.build_incoming_interaction
        expect(incoming_sms.topic).to eq(mandate)
      end
    end

    it "returns nil if multiple mandates were having the same phone number" do
      create(:mandate, phone: phone_number)
      incoming_sms = subject.build_incoming_interaction
      expect(incoming_sms).to be_nil
    end

    it "returns nil if no mandates with the incoming phone number has been found" do
      invalid_sms_data                       = {}
      invalid_sms_data["senderAddress"]      = "not an existing phone"
      invalid_sms_data["textMessageContent"] = "content"
      incoming_sms = described_class.new(invalid_sms_data).build_incoming_interaction
      expect(incoming_sms).to be_nil
    end
  end
end
