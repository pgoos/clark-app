# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "a vertical specific inquiry mailer" do |mailer_method, subject_method|
  let(:vertical_ident) { Vertical::VERTICAL_IDENTS.first }
  let(:inquiry) { instance_double(Inquiry, categories: categories) }
  let(:categories) { [] }
  let(:allianz_settings) { Settings.insurance_carriers["allia8c23e2"] }

  context "choose email" do
    let(:mail) { double("mail") }

    before do
      allow(mail).to receive(:deliver_now)
      allow(InquiryMailer).to receive(mailer_method).with(any_args).and_return(mail)
    end

    it "should send the inquiry mail to the right mail address" do
      expected_address = allianz_settings.vertical_mapping[vertical_ident]

      categories << instance_double(Category, vertical_ident, vertical_ident: vertical_ident)

      expect(InquiryMailer)
        .to receive(mailer_method)
          .with(
            inquiry:                inquiry,
            categories:             categories,
            ident:                  "allia8c23e2",
            insurer_mandates_email: expected_address
          )
          .and_return(mail)

      subject.send(subject_method, inquiry)
    end

    it "should send the mail" do
      categories << instance_double(Category, vertical_ident, vertical_ident: vertical_ident)

      expect(mail).to receive(:deliver_now)

      subject.send(subject_method, inquiry)
    end
  end

  context "send mail specific for vertical with right categories" do
    let(:category_mapping) { {} }
    let(:mail_doubles) { {} }

    before do
      Vertical::VERTICAL_IDENTS.each do |ident|
        category = instance_double(Category, ident, vertical_ident: ident)
        categories << category

        mail_address = allianz_settings.vertical_mapping[ident]
        category_mapping[mail_address] = [] if category_mapping[mail_address].nil?
        category_mapping[mail_address] << category

        mail_doubles[mail_address] = double("mail_#{ident}") if mail_doubles[mail_address].nil?
      end
    end

    it "should send the categories for the right verticals only" do
      category_mapping.each do |mail_address, mapped_categories|
        current_mail_double = mail_doubles[mail_address]
        expect(InquiryMailer)
          .to receive(mailer_method)
          .with(
            inquiry:                inquiry,
            categories:             mapped_categories,
            ident:                  "allia8c23e2",
            insurer_mandates_email: mail_address
          )
          .and_return(current_mail_double)
        expect(current_mail_double).to receive(:deliver_now)
      end

      subject.send(subject_method, inquiry)
    end
  end
end
