# frozen_string_literal: true

require "rails_helper"

RSpec.describe OfferMailer, :integration, type: :mailer do
  let!(:offer)       { create :offer, mandate: mandate, opportunity: opportunity }
  let(:product)      { create(:product, inquiry: create(:inquiry)) }
  let(:mandate)      { build(:mandate, user: user, state: :created) }
  let(:user)         { build(:user, email: email, subscriber: true) }
  let(:email)        { "whitfielddiffie@gmail.com" }
  let(:opportunity)  { build(:opportunity, category: category) }
  let(:category)     { build(:category) }
  let(:documentable) { offer }

  describe "#offer_available_top_price" do
    let(:mail) { OfferMailer.offer_available_top_price(offer) }

    include_examples "checks mail rendering"

    it "includes a link to the offer", skip: "Failing because of changed encoding" do
      original_link = CGI.escape("http://test.host/de/app/offer/#{offer.id}?app_redirect=false")
      expect(mail.body.encoded).to match(original_link)
    end

    describe "with ahoy email tracking" do
      let(:document_type) { DocumentType.offer_available_top_price }

      it "includes the tracking pixel" do
        expect(mail.body.encoded).to include("open.gif")
      end

      it "replaces links with tracking links", skip: "Failing because of changed encoding" do
        original_link       = "https://www.facebook.com/ClarkGermany"
        tracking_parameters = "utm_campaign=offer_available_top_price&utm_medium=email&utm_source=offer_mailer"
        tracking_link       = /http:\/\/test.host\/ahoy\/messages\/\w{32}\/click\?signature=\w{40}&amp;url=#{CGI.escape(original_link + "?" + tracking_parameters)}/
        expect(mail.body.encoded).to match(tracking_link)
      end

      it_behaves_like("stores a message object upon delivery", "OfferMailer#offer_available_top_price", "offer_mailer", "offer_available_top_price")
      it_behaves_like "tracks document and mandate in ahoy email"
    end

    it_behaves_like "does not send out an email if mandate belongs to the partner"
  end

  describe "#offer_available_top_price" do
    let(:mail) { OfferMailer.offer_available_top_cover(offer) }
    let(:document_type) { DocumentType.offer_available_top_cover }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
    it_behaves_like "does not send out an email if mandate belongs to the partner"
  end

  describe "#offer_available_top_cover_and_price" do
    let(:mail) { OfferMailer.offer_available_top_cover_and_price(offer) }
    let(:document_type) { DocumentType.offer_available_top_cover_and_price }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
    it_behaves_like "does not send out an email if mandate belongs to the partner"
  end

  describe "#new_product_offer_available" do
    let(:mail) { OfferMailer.new_product_offer_available(offer) }
    let(:document_type) { DocumentType.new_product_offer_available }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
    it_behaves_like "does not send out an email if mandate belongs to the partner"
  end

  describe "#offer_reminder1" do
    let(:mail) { OfferMailer.offer_reminder1(offer) }
    let(:document_type) { DocumentType.offer_reminder1 }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
    it_behaves_like "does not send out an email if mandate belongs to the partner"
  end

  describe "#offer_reminder2" do
    let(:mail) { OfferMailer.offer_reminder2(offer) }
    let(:document_type) { DocumentType.offer_reminder2 }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
    it_behaves_like "does not send out an email if mandate belongs to the partner"
  end

  describe "#offer_reminder3" do
    let(:mail) { OfferMailer.offer_reminder3(offer) }
    let(:document_type) { DocumentType.offer_reminder3 }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
    it_behaves_like "does not send out an email if mandate belongs to the partner"
  end

  describe "#offer_appointment_request" do
    let(:appointment_data) { {date: "some date"}.stringify_keys }
    let(:mail)             { OfferMailer.offer_appointment_request(offer, appointment_data) }

    before do
      allow(offer).to receive(:opportunity)
        .and_return(OpenStruct.new(id: 1, admin: OpenStruct.new(email: "admin@example.com")))
    end

    include_examples "does not track email in ahoy"
    it_behaves_like "does not send out an email if mandate belongs to the partner"
  end

  describe "#offer_appointment_confirmation_phone_call" do
    let(:mail)         { OfferMailer.offer_appointment_confirmation_phone_call(appointment) }
    let(:appointment)  { create(:appointment, appointable: opportunity, mandate: mandate) }
    let(:document_type) { DocumentType.offer_appointment_confirmation_phone_call }
    let(:documentable) { offer.opportunity }

    include_examples "checks mail rendering" do
      let(:html_part) { "appointment-container" }
    end

    it_behaves_like "tracks document and mandate in ahoy email"
    it_behaves_like "does not send out an email if mandate belongs to the partner"

    it "has a '.ics' attachment file" do
      attachment = mail.attachments[0]

      expect(attachment).to be_a_kind_of(Mail::Part)
      expect(attachment.content_type).to eq("text/calendar")
      expect(attachment.filename).to eq("appointment.ics")
    end
  end

  describe "#offer_thank_you" do
    let(:mail) { OfferMailer.offer_thank_you(offer) }
    let(:document_type) { DocumentType.offer_thank_you }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
  end

  describe "#offer_documents" do
    before do
      allow(offer).to receive(:accepted_product).and_return(product)
    end

    let(:mail) { OfferMailer.offer_documents(offer) }
    let(:document_type) { DocumentType.offer_documents }

    include_examples "checks mail rendering"
    it "sends ahoy email" do
      expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(1)
    end

    describe "sending is disabled by mandate settings" do
      before do
        allow(offer.mandate).to receive(:mailing_allowed?).and_return(false)
      end

      it "does not sends ahoy email" do
        expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(0)
      end
    end

    describe "sending is disabled by permissions" do
      before do
        allow_any_instance_of(OutboundChannels::DeliveryPermission).to receive(:interaction_allowed_for?).and_return(false)
      end

      it "does not sends ahoy email" do
        expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(0)
      end
    end
  end

  describe "#offer_request_iban" do
    let(:mail) { OfferMailer.offer_request_iban(mandate) }
    let(:document_type) { DocumentType.offer_request_iban }
    let(:documentable) { mandate }

    include_examples "checks mail rendering"
    it_behaves_like "tracks document and mandate in ahoy email"
    it_behaves_like "does not send out an email if mandate belongs to the partner"
  end
end
