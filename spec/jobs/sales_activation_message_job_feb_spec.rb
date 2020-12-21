# frozen_string_literal: true

require "rails_helper"

describe SalesActivationMessageFebJob, type: :job do
  describe ".perform" do
    let(:mandate) { double(:mandate, id: 1, first_name: "Thanos") }
    let(:admin) { double(:admin) }
    let(:message) { double(:message) }
    let(:variant_name) { "Group2a" }

    before do
      allow(Mandate).to receive(:find_by).with(id: mandate.id).and_return(mandate)
      allow(Admin).to receive(:bot).and_return(admin)
      allow(Interaction::Message).to receive(:new).with(interaction_attributes).and_return(message)
    end

    it "dispatches the messenger message" do
      expect(Domain::Messenger::Messages::Outgoing::Dispatch).to receive(:call).with(message)
      subject.perform(mandate.id, variant_name)
    end
  end

  def interaction_attributes
    content = "Hallo #{mandate.first_name},\n\n"\
    "eines ist sicher: In Zukunft ist die gesetzliche Rente nur noch eine Grundsicherung. 80% fürchten die Altersarmut! Sie verlassen sich nicht auf die gesetzliche Rente und sorgen privat vor.\n\n"\
    "Nimm deine Altersvorsorge selbst in die Hand und vereinbare einen unverbindlichen Beratungstermin mit uns.\n\n"\
    "Viele Grüße\n"\
    "Dein CLARK-Team"

    metadata = {
      cta_link: "/app/retirement/appointment",
      cta_text: "Termin vereinbaren",
      message_type: Interaction::Message::MESSAGE_TYPES["text"],
      created_by_robo: false,
      experiment_name: "Sales_Activation_Campaign_Feb2020",
      variant_name: variant_name
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
