# frozen_string_literal: true

require "rails_helper"

RSpec.describe AllianzInquiryMailer, :integration, type: :mailer do
  let(:mandate) { create :mandate, user: user, state: :created }
  let(:user)    { create :user, email: email, subscriber: true }
  let(:email)   { "whitfielddiffie@gmail.com" }

  describe "#insurance_request" do
    let(:company) { create(:company, ident: "allia8c23e2") }
    let(:subcompany) { create(:subcompany, ident: "allia525dda") }
    let(:inquiry) { create(:inquiry, mandate: mandate, company: company, subcompany: subcompany) }

    let(:mail) do
      AllianzInquiryMailer.insurance_request(inquiry: inquiry, categories: inquiry.categories,
                                      ident: inquiry.company.ident)
    end

    it "renders the email successfully" do
      expect(mail.subject).to match("Auskunftsanfrage")
      expect(mail.subject).to match("VT = 7/581/2494 KT = U0031, HS = KV, HSG = KV")
      part = "anbei erhalten Sie die aktuelle Maklervollmacht des im Betreff genannten Kunden."
      expect(mail.body.encoded).to match(part)
    end

    include_examples "does not track email in ahoy"

    context "gkv" do
      let(:gkv_company) { create(:gkv_company) }

      before do
        inquiry.company = gkv_company
        inquiry.save
      end

      it "does not send insurance requests for GKV inquires" do
        expect(mail.message).to be_a(ActionMailer::Base::NullMail)
      end

      it "does not add business events for GKV inquires" do
        expect(BusinessEvent).not_to receive(:audit)
        mail.message # it's not enough to use the mail call solely to make the test pass/fail
      end
    end
  end

  describe "#direct_transfer_request" do
    let(:product) { create :product, mandate: mandate }
    let(:mail)    {
      AllianzInquiryMailer.direct_transfer_request(from: Settings.emails.service,
                                            to: email,
                                            cc: email,
                                            subject: "custom subject",
                                            csv_name: "mandate.pdf",
                                            csv: "some csv content",
                                            mandate_docs: [])
    }

    it "tracks document" do
      expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(1)
    end
  end
end
