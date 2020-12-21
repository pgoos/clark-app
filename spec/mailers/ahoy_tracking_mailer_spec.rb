# frozen_string_literal: true

require "rails_helper"

RSpec.describe AhoyTrackingMailer, :integration, type: :mailer do
  let!(:mandate) { create :mandate, user: user, state: :created }
  let(:user)     { create :user, email: email, subscriber: true }
  let(:email)    { "whitfielddiffie@gmail.com" }


  let(:pdf_generator) { PdfGenerator::Generator }


  describe "Ahoy Tracking Mailer" do
    let(:mail) { AhoyTrackingMailer.send_email(mandate) }

    include_examples "checks mail rendering"
    context "will only run in specific environments" do

      it "does not run in production" do
        allow(Rails).to receive(:env) { "production".inquiry }
        expect { subject.send_email(nil) }
          .to raise_error(StandardError, "AhoyTrackingMailer only available in testing")
      end
    end


    context "changes when sending the email" do
      before do
        allow(PdfGenerator::Generator).to receive(:pdf_from_html).and_return("data:application/pdf;base64,Some base 64")
      end

      it "creates an ahoy message" do
        expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(1)

        message = Ahoy::Message.last
        expect(message.to).to eq(email)
        expect(message.token).to match(/\w{32}/)
        expect(message.mailer).to eq("AhoyTrackingMailer#send_email")
        expect(message.utm_medium).to eq("email")
        expect(message.utm_source).to eq("ahoy_tracking_mailer")
        expect(message.utm_campaign).to eq("send_email")
      end

      it "tracks email as document at mandate" do
        expect { mail.deliver_now }.to change { Document.count }.by(1)

        document = Document.last
        expect(document.document_type).to eq(DocumentType.greeting)
        expect(document.documentable_id).to eq(mandate.id)
        expect(document.documentable_type).to eq(mandate.class.to_s)
      end

    end

    context "email with tracking" do

      before(:example) do
        allow(PdfGenerator::Generator).to receive(:pdf_from_html).and_return("data:application/pdf;base64,Some base 64")
        mail.deliver_now
      end

      it "replaces links with tracking links" do
        signature_length =  "b6357e7004d2c53dc8c6342e614e8581113aecd5".length
        message_length =  "Pm154w734SA4G3Hjm6hGHphQMG6IF9At".length

        original_link       = "https://www.facebook.com/ClarkGermany/"
        tracking_parameters = "utm_source=ahoy_tracking_mailer&utm_medium=email&utm_campaign=send_email"
        tracking_link       = /http:\/\/test.host\/ahoy\/messages\/\w{#{message_length}}\/click\?signature=\w{#{signature_length}}&amp;url=#{CGI.escape(original_link + "?" + tracking_parameters)}/
        expect(mail.html_part.decoded.gsub("\n",'')).to match(tracking_link)
      end

      it "includes the open pixel" do
        expect(mail.body.encoded).to match(/open.gif/)
        expect(mail.body.encoded).to match(/the ahoy tracking email1234ASDF/)
      end

      it "sends clean html to the PDF generator so the open pixel is not fired" do
        clean_html = Ahoy.cleanup_tracking_code(mail.html_part.decoded)
        expect(PdfGenerator::Generator).to have_received(:pdf_from_html).with(clean_html)
      end
    end
  end
end
