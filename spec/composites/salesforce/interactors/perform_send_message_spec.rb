# frozen_string_literal: true

require "rails_helper"

RSpec.describe Salesforce::Interactors::PerformSendMessage, :integration do
  subject { described_class.new }

  it "performs job for send message" do
    params = { customer_id: 1, message_text: "Hello", cta_text: "hey", cta_link: "https://google.com" }
    expect {
      subject.call(params)
    }.to have_enqueued_job.on_queue("salesforce")
  end
end
