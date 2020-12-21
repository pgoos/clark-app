# frozen_string_literal: true

require "rails_helper"

describe SalesActivationMessageJob, type: :job do
  describe ".perform" do
    let(:mandate) { double(:mandate, id: 1, first_name: "Thanos") }
    let(:admin) { double(:admin) }
    let(:message) { double(:message) }

    before do
      allow(Mandate).to receive(:find_by).with(id: mandate.id).and_return(mandate)
      allow(Admin).to receive(:bot).and_return(admin)
      allow(Interaction::Message).to receive(:new).with(interaction_attributes).and_return(message)
    end

    it "dispatches the messenger message" do
      expect(Domain::Messenger::Messages::Outgoing::Dispatch).to receive(:call).with(message)
      subject.perform(mandate.id)
    end
  end

  def interaction_attributes
    content = "Hallo #{mandate.first_name},\n\n"\
    "bezüglich deiner Versicherungssituation haben wir versucht dich telefonisch zu erreichen. Leider ohne Erfolg.\n\n"\
    "Bitte schreibe uns, wann du am besten erreichbar bist oder vereinbare hier einen Rückruftermin mit uns.\n\n"\
    "Wir freuen uns auf deine Rückmeldung.\n\n"\
    "Viele Grüße,\n"\
    "Dein CLARK-Team"

    metadata = {
      cta_link: "/app/retirement/appointment",
      cta_text: "Termin vereinbaren",
      message_type: Interaction::Message::MESSAGE_TYPES["text"],
      created_by_robo: false
    }

    {
      mandate: mandate,
      admin: admin,
      direction: Interaction.directions[:out],
      content: content,
      metadata: metadata
    }
  end
end
