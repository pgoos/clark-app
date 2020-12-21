# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Inquiries::MailResolvers::Allianz do
  subject do
    Class.new do
      include Domain::Inquiries::MailResolvers::Allianz
    end.new
  end

  let(:inquiry) { instance_double(Inquiry, categories: categories) }
  let(:categories) { [] }
  let(:allianz_settings) { Settings.insurance_carriers["allia8c23e2"] }

  before :context do
    # It's safe to reload the settings here before context, since they're usually static during
    # the runtime of the application anyway.
    Settings.reload!
  end

  context "mail exists" do
    Vertical::VERTICAL_IDENTS.each do |ident|
      it "should have the according email address in the settings" do
        expect(allianz_settings.vertical_mapping[ident]).to match(/.+@.+/)
      end
    end
  end

  context "maps to the right email" do
    Vertical::VERTICAL_IDENTS.each do |ident|
      it "should send the inquiry mail to the right mail address" do
        expected_address = allianz_settings.vertical_mapping[ident]

        categories << instance_double(Category, ident, vertical_ident: ident)

        mapping = subject.perform_mapping(inquiry)

        expect(mapping[expected_address]).to eq(categories)
      end
    end
  end
end
