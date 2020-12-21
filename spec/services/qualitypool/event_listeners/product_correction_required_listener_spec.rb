# frozen_string_literal: true

require "rails_helper"
require "services/qualitypool/event_listeners/event_fixtures"

RSpec.describe Qualitypool::EventListeners::ProductCorrectionRequiredListener do
  include_context "event fixtures"

  subject(:event_listener) { described_class }
  let(:event_type_key) { Qualitypool::PullEventService::EVENT_TYPE_KEY }

  it "should respond to name with the class name" do
    expected_name = "Qualitypool::EventListeners::ProductCorrectionRequiredListener"
    expect(event_listener.name).to eq(expected_name)
  end

  it "should do nothing for a terminated product" do
    product = instance_double(Product)
    expect(product).to receive(:terminated?).and_return(true)
    # rspec will fail, if the product double receives any other messages than the expected
    event_listener.process_event(response.result, product, mailer_double)
  end

  context "event listening" do
    before do
      allow(product).to receive(:terminated?).and_return(false)
    end

    # TODO: https://clarkteam.atlassian.net/browse/JCLARK-12536
    # it "listens to 'Bestandsübertragung Nachbearbeitung'" do
    #   response.result[event_type_key] = described_class::EVENT_PORTFOLIO_TRANSFER_CORRECTION
    #   expect(product).to receive(:request_corrections!)
    #   event_listener.process_event(response.result, product, mailer_double)
    # end

    it "sends a mail to operations, if 'Bestandsübertragung Nachbearbeitung'" do
      response.result[event_type_key] = described_class::EVENT_PORTFOLIO_TRANSFER_CORRECTION
      message_type                    = Qualitypool::PullEventService::ProductCorrectionRequiredMessage
      expect(mailer_double).to receive(:send_plain_text).with(mail_from, mail_to, message_type)
      event_listener.process_event(response.result, product, mailer_double)
    end

    it "should fail, if the listener is processed for an event, which it cannot process" do
      event                           = "not understood #{rand}"
      response.result[event_type_key] = event
      name                            = described_class.name
      error_message                   = "The event '#{event}' cannot be processed by the event listener '#{name}'."
      expect {
        event_listener.process_event(response.result, product, mailer_double)
      }.to raise_error(error_message)
    end

    it "should be declared in the pull event service" do
      expected_to_be_included = {
        described_class::EVENT_PORTFOLIO_TRANSFER_CORRECTION => [described_class]
      }
      expect(Qualitypool::PullEventService.listeners).to include(expected_to_be_included)
    end
  end
end
