# frozen_string_literal: true

require "rails_helper"
RSpec.describe Domain::Interactions::Sms do
  let(:user)        { create(:user) }
  let(:mandate)     { create(:mandate, user: user) }
  let(:admin)       { create(:admin) }
  let(:subject) { described_class.new(mandate, admin) }

  let(:valid_sms_data) {
    {
      interaction_sms: {
        phone_number: "015123456789"
      }
    }
  }

  let(:invalid_sms_data) {
    {
      interaction_sms: {
        phone_number: "015123456sdd9"
      }
    }
  }

  let(:success_message) { "SMS erfolgreich gesendet" }
  let(:failure_message_normal) { "Da ging was schief!" }
  let(:failure_message_special) { "SMS kann nicht gesendet werden" }

  let(:content) { "some content" }

  describe ".send" do
    it "sends message succesfully if valid sms data" do
      message = subject.send(content, valid_sms_data)
      expect(message).to eq(success_message)
    end

    it "returns error message if sms data is invalide" do
      message = subject.send(content, invalid_sms_data)
      expect(message).to eq(failure_message_special)
    end
  end

end
