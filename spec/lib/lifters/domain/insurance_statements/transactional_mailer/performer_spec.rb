# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::InsuranceStatements::TransactionalMailer::Performer do
  subject { Core::TransactionalMailer.new(Logger.new("/dev/null")) }

  let(:questionnaire) { Questionnaire.bedarfscheck }
  let(:user) { create(:user, subscriber: true) }
  let(:mandate) { create(:mandate, :accepted, user: user) }

  before do
    allow_any_instance_of(Domain::InsuranceStatements::InsuranceStatement).to \
      receive(:candidate?).and_return(true)
    allow(Features).to receive(:active?).with(any_args).and_return(false)
    allow(Features).to receive(:active?).with(Features::INSURANCE_STATEMENT_EMAILS).and_return(true)

    create(:bedarfscheck_questionnaire)
    create(:document_type, template: "mandate_mailer/insurance_statement")
    create(:inquiry, :accepted, mandate: mandate)

    Timecop.freeze(Time.zone.now.noon)
  end

  after do
    Timecop.return
  end

  describe "#insurance_statement1" do
    context "Customer never finished the demand-check" do
      let(:other_questionnaire) { create(:questionnaire) }

      before do
        create(:questionnaire_response, mandate:       mandate,
                                        finished_at:   20.days.ago,
                                        questionnaire: other_questionnaire)
      end

      it "should not send any insurance statement" do
        expect(MandateMailer).not_to receive(:insurance_statement)
        subject.insurance_statement1
      end
    end

    context "mandate made the demand-check less than one month ago" do
      before do
        create(:questionnaire_response, mandate:       mandate,
                                        finished_at:   1.month.ago,
                                        questionnaire: questionnaire)
      end

      it "should not receive any statement before 1 month" do
        expect(MandateMailer).not_to receive(:insurance_statement)
        subject.insurance_statement1
      end
    end

    context "mandate made the demand-check more than one month ago" do
      before do
        create(:questionnaire_response, mandate:       mandate,
                                        finished_at:   (1.month + 1.day).ago,
                                        questionnaire: questionnaire)
      end

      context "mandate has not received a statement before" do
        context "mandate has no recommendations" do
          before do
            allow_any_instance_of(Domain::InsuranceStatements::InsuranceStatement).to \
              receive(:candidate?).and_return(false)
          end

          it "should not receive the insurance statement" do
            expect(MandateMailer).not_to receive(:insurance_statement)
            subject.insurance_statement1
          end
        end
      end

      it "should receive an statement" do
        expect(MandateMailer).to receive(:insurance_statement)
          .with(kind_of(Mandate), kind_of(Domain::InsuranceStatements::InsuranceStatement))
          .and_call_original

        subject.insurance_statement1
      end

      it "should not receive a statement, if the feature is switched off" do
        allow(Features).to receive(:active?).with(Features::INSURANCE_STATEMENT_EMAILS).and_return(false)
        expect(MandateMailer).not_to receive(:insurance_statement)
        subject.insurance_statement1
      end

      context "mandate received insurance statement within a month" do
        before do
          create(:document, document_type: DocumentType.insurance_statement,
                            documentable:  mandate,
                            created_at:    1.month.ago)
        end

        it "should not receive an email" do
          expect(MandateMailer).not_to receive(:insurance_statement)
          subject.insurance_statement1
        end
      end
    end
  end

  context "#insurance_statement2" do
    context "mandate received the first statement but not the second" do
      before do
        create(:questionnaire_response, mandate:       mandate,
                                        finished_at:   (4.months + 1.day).ago,
                                        questionnaire: questionnaire)
        create(:document, document_type: DocumentType.insurance_statement,
                          documentable:  mandate,
                          created_at:    (3.months + 1.day).ago)
      end

      context "mandate has no recommendations" do
        before do
          allow_any_instance_of(Domain::InsuranceStatements::InsuranceStatement).to \
            receive(:candidate?).and_return(false)
        end

        it "should not receive the insurance statement" do
          expect(MandateMailer).not_to receive(:insurance_statement)
          subject.insurance_statement2
        end
      end

      it "should receive the second statement" do
        expect(MandateMailer).to receive(:insurance_statement)
          .with(kind_of(Mandate), kind_of(Domain::InsuranceStatements::InsuranceStatement))
          .and_call_original

        subject.insurance_statement2
      end

      it "should not receive a statement, if the feature is switched off" do
        allow(Features).to receive(:active?).with(Features::INSURANCE_STATEMENT_EMAILS).and_return(false)
        expect(MandateMailer).not_to receive(:insurance_statement)
        subject.insurance_statement2
      end
    end

    context "mandate already received second statement" do
      before do
        create(:questionnaire_response, mandate:       mandate,
                                        finished_at:   (4.months + 2.days).ago,
                                        questionnaire: questionnaire)
        create(:document, document_type: DocumentType.insurance_statement,
                          documentable:  mandate,
                          created_at:    (3.months + 2.days).ago)
        create(:document, document_type: DocumentType.insurance_statement,
                          documentable:  mandate,
                          created_at:    1.day.ago)
      end

      it "should not receive the second statement" do
        expect(MandateMailer).not_to receive(:insurance_statement)
        subject.insurance_statement2
      end
    end
  end

  describe "#insurance_statement_summary" do
    context "mandate already received the summary before within 6 months" do
      before do
        create(:questionnaire_response, mandate:       mandate,
                                        finished_at:   10.months.ago,
                                        questionnaire: questionnaire)
      end

      it "should not send more than once" do
        create(:document, document_type: DocumentType.insurance_statement,
                          documentable:  mandate,
                          created_at:    6.months.ago)
        expect(MandateMailer).not_to receive(:insurance_statement)
        subject.insurance_statement_summary
      end
    end

    context "mandate is eligible to receive the summary mail" do
      before do
        create(:questionnaire_response, mandate:       mandate,
                                        finished_at:   (10.months + 1.day).ago,
                                        questionnaire: questionnaire)
      end

      context "mandate has no recommendations" do
        before do
          allow_any_instance_of(Domain::InsuranceStatements::InsuranceStatement).to \
            receive(:candidate?).and_return(false)
        end

        it "should not receive the insurance statement" do
          expect(MandateMailer).not_to receive(:insurance_statement)
          subject.insurance_statement_summary
        end
      end

      it "should send half-yearly summary" do
        create(:document, document_type: DocumentType.insurance_statement,
                          documentable:  mandate,
                          created_at:    (6.months + 1.day).ago)
        expect(MandateMailer).to receive(:insurance_statement)
          .with(kind_of(Mandate), kind_of(Domain::InsuranceStatements::InsuranceStatement))
          .and_call_original

        subject.insurance_statement_summary
      end

      it "should not receive a statement, if the feature is switched off" do
        allow(Features).to receive(:active?).with(Features::INSURANCE_STATEMENT_EMAILS).and_return(false)
        expect(MandateMailer).not_to receive(:insurance_statement)
        subject.insurance_statement_summary
      end
    end
  end
end
