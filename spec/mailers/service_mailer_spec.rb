# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceMailer, :integration, type: :mailer do
  let!(:admin)       { create(:gkv_consultants_admin) }
  let!(:mandate)     { create :mandate, user: user, state: :created }
  let(:user)         { create :user, email: email, subscriber: true }
  let(:email)        { "whitfielddiffie@gmail.com" }
  let(:data)         { {email: email, firstName: "Whitfield", lastName: "Diffie"}.stringify_keys }
  let(:title)        { "My E-mail title" }
  let(:documentable) { mandate }

  describe "#ppc_email_form_results" do
    let(:mail) { ServiceMailer.ppc_email_form_results("zahnzusatz", title, data, mandate) }

    include_examples "does not track email in ahoy"
    include_examples "checks mail rendering"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#gkv_appointment_confirmation_email" do
    let(:data) {
      { email:            email,
        firstName:        "Whitfield",
        lastName:         "Diffie",
        appointment_date: 10.years.ago.strftime("%d.%m.%Y"),
        appointment_time: 10.years.ago.strftime("%d.%m.%Y")
      }.stringify_keys
    }
    let(:mail) { ServiceMailer.gkv_appointment_confirmation_email("zahnzusatz", data, mandate) }
    let(:document_type) { DocumentType.gkv_appointment_confirmation_email }

    include_examples "tracks document and mandate in ahoy email"
    include_examples "checks mail rendering"
    include_examples "does not send out an email if mandate belongs to the partner"
  end

  describe "#direct_sales_sale" do
    let(:data) {
      {customer: {
        creation_time_email: Time.zone.now,
        firstName: "Whitfield",
        lastName: "Diffie",
        birthdate: "1988-03-31T23:00:00.000Z",
        insurance: {type: "Hund", animal: {date_of_birth: "2019-01-31T23:00:00.000Z"},
                    begins: "2019-03-31T23:00:00.000Z"}
      },
       email: {
         heading: "Mr."
       }
      }
    }

    let(:mail) { ServiceMailer.direct_sales_sale(title, data, mandate, false) }
    let(:document_type) { DocumentType.direct_sales_sale }

    include_examples "tracks document and mandate in ahoy email"
    include_examples "checks mail rendering"
  end

  describe "#mapping_changed_notification_email" do
    let(:data) {
      ["Some mapping value"]
    }

    let(:mail) { ServiceMailer.mapping_changed_notification_email(data) }

    include_examples "checks mail rendering"
  end
end
