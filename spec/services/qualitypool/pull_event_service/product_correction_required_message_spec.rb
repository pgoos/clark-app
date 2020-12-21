# frozen_string_literal: true

require "rails_helper"
require "lifters/outbound_channels/mailer"
require "services/qualitypool/event_listeners/event_fixtures"

RSpec.describe Qualitypool::PullEventService::ProductCorrectionRequiredMessage do
  include_context "event fixtures"
  it_behaves_like "a plain text message"

  subject(:message) do
    Qualitypool::PullEventService::ProductCorrectionRequiredMessage.new(product, response.result)
  end

  let(:event_id) { (rand * 100).round }
  let(:subject_key) { "admin.qualitypool.pull_events.messages.product_correction_required.subject" }
  let(:body_key) { "admin.qualitypool.pull_events.messages.product_correction_required.body" }

  before do
    response.result[:EreignisID] = event_id
  end

  it "should render the subject" do
    mail_subject = I18n.t(subject_key, product_id: local_product_id)

    rendered_subject = message.subject

    expect(rendered_subject).to eq(mail_subject)
  end

  it "should render the body" do
    body_key      = "admin.qualitypool.pull_events.messages.product_correction_required.body"
    event_data    = JSON.pretty_generate(response.result)
    expected_body = I18n.t(
      body_key,
      product_id: local_product_id,
      event_data: event_data
    )

    rendered_body = message.body
    expect(rendered_body).to eq(expected_body)
  end
end
