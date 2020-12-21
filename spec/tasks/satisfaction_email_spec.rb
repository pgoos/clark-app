# frozen_string_literal: true

require "rails_helper"

describe "rake satisfaction_email:send_to_missed_mandates", type: :task do
  let(:mandate) { create :mandate }
  let(:repository) { object_double Domain::CustomerSurvey::RecipientsRepository.new, accepted_at: [mandate] }

  let(:mail) { double :mail, subject: "Bla" }
  let(:mailer) { double :mailer, deliver_now: mail }

  before do
    allow(Domain::CustomerSurvey::RecipientsRepository).to receive(:new).and_return repository
    allow(Features).to receive(:active?).and_return true
    create(:document_type, template: "customer_survey_mailer/satisfaction") unless DocumentType.satisfaction_email
    Timecop.freeze(Time.zone.now)
  end

  after { Timecop.return }

  context "when feature switch is off" do
    before { allow(Features).to receive(:active?).with(Features::SATISFACTION_EMAIL).and_return false }

    it "does not send any emails" do
      expect(repository).not_to receive(:accepted_at)
      task.invoke
    end
  end

  context "when feature switch is on" do
    before { allow(Features).to receive(:active?).with(Features::SATISFACTION_EMAIL).and_return true }

    context "when no document for satisfaction mail exists" do
      it "does not send any emails" do
        expect(repository).not_to receive(:accepted_at)
        task.invoke
      end
    end

    context "when document for satisfaction mail exists" do
      let!(:document) { create :document, :satisfaction_document, created_at: 1.weeks.ago }

      before do
        allow(CustomerSurveyMailer).to receive(:satisfaction).and_return mailer
      end

      it "send satisfaction emails" do
        range = (document.created_at - 8.weeks).beginning_of_day..8.weeks.ago.end_of_day
        expect(repository).to receive(:accepted_at).with(range)
        expect(CustomerSurveyMailer).to receive(:satisfaction).with(mandate)
        expect(mailer).to receive(:deliver_now)
        task.invoke
      end

      it "generates a new interaction" do
        expect { task.invoke }.to change { mandate.interactions.count }.by(1)
        email = mandate.interactions.last
        expect(email).to be_kind_of Interaction::Email
        expect(email.direction).to eq "out"
        expect(email.topic).to eq mandate
      end
    end
  end
end
