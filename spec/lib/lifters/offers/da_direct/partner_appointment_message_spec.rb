# frozen_string_literal: true

require "rails_helper"
require "lifters/outbound_channels/mailer"
require "lifters/offers/da_direct/partner_appointment_message"

RSpec.describe Sales::DaDirect::PartnerAppointmentMessage do
  subject { Sales::DaDirect::PartnerAppointmentMessage.new(mandate, partner_datum, appointment) }

  let(:birthdate) { "1.1.80" }
  let(:random_int) { (rand * 100).to_i }
  let(:full_name) { "Clark Bottich#{random_int}" }
  let(:phone) { "069 123 456 #{random_int}" }
  let(:mandate) { double(Mandate) }
  let(:partner_datum) { double(ProductPartnerDatum) }
  let(:appointment) { double(Appointment) }
  let(:starts) { DateTime.current }
  let(:ends) { starts.advance(hours: 2) }
  let(:date) { starts.to_date }
  let(:agent) { Settings.clark_agent }

  let(:parameters) do
    {
      "param_1" => "value 1 #{random_int}",
        "param_2" => "value 2 #{random_int}",
        "premium_period" => "year",
        "premium" => {"value" => 424.35 + random_int, "currency" => "EUR"},
        "replacement_premium" => {"value" => 410.53 + random_int, "currency" => "EUR"},
        "gender" => "male",
        "birthdate" => birthdate
    }
  end

  before do
    allow(mandate).to receive(:full_name).and_return(full_name)
    allow(mandate).to receive(:phone).and_return(phone)

    allow(partner_datum).to receive(:product_id).and_return(random_int)
    allow(partner_datum).to receive(:data).and_return(parameters)

    allow(appointment).to receive(:starts).and_return(starts)
    allow(appointment).to receive(:ends).and_return(ends)
    allow(appointment).to receive(:date).and_return(date)
  end

  it "should contain the proper subject" do
    expect(subject.subject).to eq("WECHSLER 17 | #{full_name} | Clark.de")
  end

  context "body" do
    def assert_body_match(value)
      expect(subject.body).to match(/#{Regexp.escape(value)}/)
    end

    it "should contain the full name" do
      assert_body_match(full_name)
    end

    it "should contain the plan name" do
      assert_body_match(Sales::DaDirect::Config.plan_name)
    end

    it "should contain the start time" do
      assert_body_match(starts.strftime("%H:%M"))
    end

    it "should contain the end time" do
      assert_body_match(ends.strftime("%H:%M"))
    end

    it "should contain the date" do
      assert_body_match(date.strftime("%d.%m.%Y"))
    end

    it "should contain the phone nr" do
      assert_body_match(phone)
    end

    it "should contain the parameters" do
      text = <<~EOPARAMS
        - param_1: #{parameters['param_1']}
        - param_2: #{parameters['param_2']}
        - Zweise: ZW1
        - Beitrag: #{ValueTypes.from_hash('Money', parameters['premium']).to_monetized} €
        - Gesamt: #{ValueTypes.from_hash('Money', parameters['replacement_premium']).to_monetized} €
        - VN Geschlecht: männlich
        - Geburtsdatum: #{birthdate}
      EOPARAMS

      assert_body_match(text)
    end

    it "should contain Clark Germany GmbH" do
      assert_body_match(agent.name)
    end

    it "should contain a signature" do
      text = <<~EOSIGNATURE
        --
        #{agent.name}
        #{agent.street} #{agent.house_number}
        #{agent.zip_code} #{agent.city}
        #{agent.phone}
        #{agent.product_team.email}
        "#{I18n.t('manager.inquiries.inquiry_mailer.ihk_name_short')}: #{agent.ihk_nr}"
      EOSIGNATURE
      assert_body_match(text)
    end
  end
end
