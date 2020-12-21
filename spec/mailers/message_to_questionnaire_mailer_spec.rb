# frozen_string_literal: true

require "rails_helper"

RSpec.describe MessageToQuestionnaireMailer, :integration, type: :mailer do
  let!(:mandate)      { create :mandate, user: user, state: :created }
  let(:user)          { create :user, email: email, subscriber: true }
  let(:email)         { "whitfielddiffie@gmail.com" }
  let(:questionnaire) { create :questionnaire }
  let(:mock_content)  { "" }
  let(:documentable)  { questionnaire }

  describe "#dental_insurance" do
    let(:mail) { MessageToQuestionnaireMailer.dental_insurance(mandate, questionnaire, mock_content) }

    include_examples "checks mail rendering"

    describe "with ahoy email tracking" do
      let(:document_type) { DocumentType.dental_insurance_email }

      it "includes the tracking pixel" do
        expect(mail.body.encoded).to include("open.gif")
      end

      it "replaces links with tracking links", skip: "Failing because of changed encoding" do
        original_link       = "https://www.facebook.com/ClarkGermany"
        tracking_parameters = "utm_campaign=dental_insurance&utm_medium=email&utm_source=message_to_questionnaire_mailer"
        tracking_link       = /http:\/\/test.host\/ahoy\/messages\/\w{32}\/click\?signature=\w{40}&amp;url=#{CGI.escape(original_link + "?" + tracking_parameters)}/
        expect(mail.body.encoded).to match(tracking_link)
      end

      include_examples "stores a message object upon delivery", "MessageToQuestionnaireMailer#dental_insurance", "message_to_questionnaire_mailer", "dental_insurance"
      include_examples "tracks document and mandate in ahoy email"
    end

    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#disability_insurance_rule" do
    let(:mail) { MessageToQuestionnaireMailer.disability_insurance_rule(mandate, questionnaire, mock_content) }
    let(:document_type) { DocumentType.disability_insurance_email }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#demand_never_rule" do
    let(:mail) { MessageToQuestionnaireMailer.demand_never_rule(mandate, questionnaire, mock_content) }
    let(:document_type) { DocumentType.demand_never_rule_email }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#demand_old_rule" do
    let(:mail) { MessageToQuestionnaireMailer.demand_old_rule(mandate, questionnaire, mock_content) }
    let(:document_type) { DocumentType.demand_old_rule_email }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#og_riester_1_insurance" do
    let(:mail) { MessageToQuestionnaireMailer.og_riester_1_insurance(mandate, questionnaire, mock_content) }
    let(:document_type) { DocumentType.og_riester_1_insurance }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#og_product_contract_end_blacklist" do
    let(:mail) { MessageToQuestionnaireMailer.og_product_contract_end_blacklist(mandate, questionnaire, mock_content) }
    let(:document_type) { DocumentType.og_product_contract_end_blacklist }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#og_blacklisted_phv" do
    let(:mail) { MessageToQuestionnaireMailer.og_blacklisted_phv(mandate, questionnaire, mock_content) }
    let(:document_type) { DocumentType.og_blacklisted_phv }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#og_blacklisted_legal_protetection" do
    let(:mail) { MessageToQuestionnaireMailer.og_blacklisted_legal_protection(mandate, questionnaire, mock_content) }
    let(:document_type) { DocumentType.og_blacklisted_legal_protection }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#og_bu_candidates_missed_by_recommendation_builder" do
    let(:mail) { MessageToQuestionnaireMailer.og_bu_candidates_missed_by_recommendation_builder(mandate, questionnaire, mock_content) }
    let(:document_type) { DocumentType.og_bu_candidates_missed_by_recommendation_builder }

    include_examples "checks mail rendering"
    include_examples "tracks document and mandate in ahoy email"
    include_examples "does not send out an email if mandate belongs to the partner"
  end
end
