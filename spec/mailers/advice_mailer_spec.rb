# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdviceMailer, :integration, type: :mailer do
  before(:all) do
    #  document types
    @reminder_reoccuring_advice_5_day  = DocumentType.reminder_reoccuring_advice_5_day
    @reminder_reoccuring_advice_2_days = DocumentType.reminder_reoccuring_advice_2_days
    @reminder_advice_35_days           = DocumentType.reminder_advice_35_days
    @reminder_1                        = DocumentType.reminder_1
  end

  let(:mandate)      { create :mandate, user: user, state: :created }
  let(:user)         { build(:user, email: "whitfielddiffie@gmail.com", subscriber: true) }
  let(:product)      { build(:product, :retirement_state_category, inquiry: build_stubbed(:inquiry)) }
  let(:offer)        { build_stubbed(:active_offer_with_old_tarif, mandate: mandate) }
  let(:opportunity)  { build_stubbed(:opportunity, state: "offer_phase", offer: offer, mandate: mandate) }
  let(:documentable) { build_stubbed(:interaction_advice, topic: product, mandate: mandate) }

  #  mails
  let(:reminder_reoccuring_advice_5_day_mail)  { AdviceMailer.reminder_reoccuring_advice_5_day(documentable) }
  let(:reminder_reoccuring_advice_2_days_mail) { AdviceMailer.reminder_reoccuring_advice_2_days(documentable) }
  let(:reminder_advice_35_days_mail)           { AdviceMailer.reminder_advice_35_days(documentable) }
  let(:reminder_1_mail)                        { AdviceMailer.reminder_1(documentable) }

  describe "#advice_reminder_reoccuring_advice_5_day" do
    let(:mail) { reminder_reoccuring_advice_5_day_mail }
    let(:document_type) { @reminder_reoccuring_advice_5_day }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#advice_reminder_reoccuring_advice_2_days" do
    let(:mail) { reminder_reoccuring_advice_2_days_mail }
    let(:document_type) { @reminder_reoccuring_advice_2_days }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#advice_reminder_advice_35_days" do
    let(:mail) { reminder_advice_35_days_mail }
    let(:document_type) { @reminder_advice_35_days }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#advice_send_reminder_1" do
    let(:mail) { reminder_1_mail }
    let(:document_type) { @reminder_1 }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end
end
