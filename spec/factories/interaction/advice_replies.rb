# frozen_string_literal: true

FactoryBot.define do
  factory :interaction_advice_reply, class: "Interaction::AdviceReply" do
    mandate
    admin
    direction    { "in" }
    content      { "Ja, schick mir doch mal bitte ein Angebot" }
    metadata     {}
    acknowledged { false }
    product
  end
end
