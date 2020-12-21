# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Inquiries::NoProductCanBeCreated do
  subject(:lifter) { described_class.new(inquiry_category.id, admin) }

  let(:admin) { create(:admin) }
  let(:inquiry) { create(:inquiry, mandate: mandate) }
  let(:mandate) { create(:mandate) }
  let(:inquiry_category) {
    create(:inquiry_category, inquiry: inquiry, customer_documents_dismissed: false)
  }
  let(:request_data) do
    {
      possible_reasons: [],
      additional_information: "Test"
    }
  end

  describe "#call" do
    it "should create an email interaction" do
      expect { subject.call }.to change(Interaction::Email, :count).by(1)
    end

    it "should have the interaction with correct properties" do
      subject.call

      interaction = Interaction::Email.last

      expect(interaction.topic).to eq(inquiry)
      expect(interaction.direction).to eq("out")
      expect(interaction.mandate).to eq(inquiry.mandate)
      expect(interaction.title).to eq("no product can be created")
      expect(interaction.content).to eq("Rückfrage zu deinem Vertrag")
      expect(interaction.admin).to eq(admin)
    end

    it "should send no_product_can_be_created email" do
      mailer_double = n_double(InquiryCategoryMailer)

      expect(InquiryCategoryMailer).to \
        receive(:no_product_can_be_created)
        .with(inquiry_category, [], "Test")
        .and_return(mailer_double)

      expect(mailer_double).to receive(:deliver_later)

      subject.call(request_data)
    end

    it "should update customer_documents_dismissed flag to true" do
      subject.call

      expect(inquiry_category.reload.customer_documents_dismissed).to eq(true)
    end
  end
end
