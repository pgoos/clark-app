# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Inquiries::InitialContacts::DropInsuranceRequest do
  subject { described_class.instance }

  let(:inquiry) { n_instance_double(Inquiry, "inquiry") }

  it "should do nothing with the inquiry" do
    # the test will fail as soon as any method call would be tried on it
    subject.send_insurance_requests(inquiry)
  end

  it "should be a single instance only in the vm" do
    expect(subject).to be_a(Singleton)
  end
end
