# frozen_string_literal: true

require "rails_helper"
require "services/qualitypool/event_listeners/event_fixtures"

RSpec.describe Qualitypool::EventListeners::PortfolioTransferStateListener do
  include_context "event fixtures"

  subject(:event_listener) { described_class }
  let(:event_type_key) { Qualitypool::PullEventService::EVENT_TYPE_KEY }

  it "should respond to name with the class name" do
    expected_name = "Qualitypool::EventListeners::PortfolioTransferStateListener"
    expect(event_listener.name).to eq(expected_name)
  end

  it "should be declared in the pull event service" do
    expected_to_be_included = {
      described_class::EVENT_PORTFOLIO_TRANSFER_SUCCESS        => [described_class],
      described_class::EVENT_PORTFOLIO_TRANSFER_DENIED         => [described_class],
      described_class::EVENT_PORTFOLIO_TRANSFER_CORRESPONDENCE => [described_class],
      described_class::EVENT_PORTFOLIO_TRANSFER_REVOKED        => [described_class]
    }
    expect(Qualitypool::PullEventService.listeners).to include(expected_to_be_included)
  end

  context "listener processing" do
    before do
      allow(product).to receive(:terminated?).and_return(false)
      allow(product).to receive(:termination_pending?).and_return(false)
      allow(product).to receive(:under_management?).and_return(false)
      allow(product).to receive(:takeover_denied?).and_return(false)
      allow(product).to receive(:correspondence?).and_return(false)
      allow(product).to receive(:managed_by_pool=).with(Subcompany::POOL_QUALITY_POOL)
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

    context "call take_under_management!" do
      before do
        response.result[event_type_key] = described_class::EVENT_PORTFOLIO_TRANSFER_SUCCESS
      end

      it "listens to 'Bestandsübertragung erfolgreich'" do
        expect(product).to receive(:take_under_management!)
        event_listener.process_event(response.result, product, mailer_double)
      end

      it "listens to 'Bestandsübertragung erfolgreich' and sets pool information" do
        expect(product).to receive(:managed_by_pool=).with(Subcompany::POOL_QUALITY_POOL).ordered
        expect(product).to receive(:take_under_management!).ordered
        event_listener.process_event(response.result, product, mailer_double)
      end

      it "listens to 'Bestandsübertragung erfolgreich' but leaves state if already there" do
        allow(product).to receive(:under_management?).and_return(true)
        expect(product).not_to receive(:take_under_management!)
        event_listener.process_event(response.result, product, mailer_double)
      end

      it "ignores 'Bestandsübertragung erfolgreich' if takeover was denied previously" do
        allow(product).to receive(:takeover_denied?).and_return(true)
        expect(product).not_to receive(:take_under_management!)
        event_listener.process_event(response.result, product, mailer_double)
      end
    end

    context "call deny_takeover!" do

      context "when denied" do
        before do
          response.result[event_type_key] = described_class::EVENT_PORTFOLIO_TRANSFER_DENIED
        end

        it "listens to 'Bestandsübertragung abgelehnt'" do
          expect(product).to receive(:deny_takeover!)
          event_listener.process_event(response.result, product, mailer_double)
        end

        it "listens to 'Bestandsübertragung abgelehnt' but leaves state if already there" do
          allow(product).to receive(:takeover_denied?).and_return(true)
          expect(product).not_to receive(:deny_takeover!)
          event_listener.process_event(response.result, product, mailer_double)
        end
      end

      context "when denied" do
        before do
          response.result[event_type_key] = described_class::EVENT_PORTFOLIO_TRANSFER_DENIED
        end

        it "listens to 'Bestandsübertragung: Maklerauftrag widerrufen'" do
          expect(product).to receive(:deny_takeover!)
          event_listener.process_event(response.result, product, mailer_double)
        end

        it "listens to 'Bestandsübertragung: Maklerauftrag widerrufen' but leaves state if already there" do
          allow(product).to receive(:takeover_denied?).and_return(true)
          expect(product).not_to receive(:deny_takeover!)
          event_listener.process_event(response.result, product, mailer_double)
        end
      end
    end

    context "call receive_correspondence!" do
      before do
        response.result[event_type_key] = described_class::EVENT_PORTFOLIO_TRANSFER_CORRESPONDENCE
      end

      it "listens to 'Bestandsübertragung courtagefrei'" do
        expect(product).to receive(:receive_correspondence!)
        event_listener.process_event(response.result, product, mailer_double)
      end

      it "listens to 'Bestandsübertragung courtagefrei' and sets pool information" do
        expect(product).to receive(:managed_by_pool=).with(Subcompany::POOL_QUALITY_POOL).ordered
        expect(product).to receive(:receive_correspondence!).ordered
        event_listener.process_event(response.result, product, mailer_double)
      end

      it "listens to 'Bestandsübertragung courtagefrei' but leaves state if already there" do
        allow(product).to receive(:correspondence?).and_return(true)
        expect(product).not_to receive(:receive_correspondence!)
        event_listener.process_event(response.result, product, mailer_double)
      end

      it "ignores 'Bestandsübertragung courtagefrei' if takeover was denied previously" do
        allow(product).to receive(:takeover_denied?).and_return(true)
        expect(product).not_to receive(:receive_correspondence!)
        event_listener.process_event(response.result, product, mailer_double)
      end
    end
  end

  context "product termination" do
    # rspec will fail, if the product double receives any other messages than the expected
    let(:product) { instance_double(Product) }

    context "product termination pending" do
      before do
        allow(product).to receive(:termination_pending?).and_return(true)
        allow(product).to receive(:terminated?).and_return(false)
      end

      it "should ignore EVENT_PORTFOLIO_TRANSFER_SUCCESS" do
        response.result[event_type_key] = described_class::EVENT_PORTFOLIO_TRANSFER_SUCCESS
        expect(product).not_to receive(:take_under_management!)
        event_listener.process_event(response.result, product, mailer_double)
      end

      it "should ignore EVENT_PORTFOLIO_TRANSFER_DENIED" do
        response.result[event_type_key] = described_class::EVENT_PORTFOLIO_TRANSFER_DENIED
        expect(product).not_to receive(:deny_takeover!)
        event_listener.process_event(response.result, product, mailer_double)
      end

      it "should ignore EVENT_PORTFOLIO_TRANSFER_CORRESPONDENCE" do
        response.result[event_type_key] = described_class::EVENT_PORTFOLIO_TRANSFER_CORRESPONDENCE
        expect(product).not_to receive(:receive_correspondence!)
        event_listener.process_event(response.result, product, mailer_double)
      end
    end

    context "product terminated" do
      before do
        allow(product).to receive(:termination_pending?).and_return(false)
        allow(product).to receive(:terminated?).and_return(true)
      end

      it "should ignore EVENT_PORTFOLIO_TRANSFER_SUCCESS" do
        response.result[event_type_key] = described_class::EVENT_PORTFOLIO_TRANSFER_SUCCESS
        expect(product).not_to receive(:take_under_management!)
        event_listener.process_event(response.result, product, mailer_double)
      end

      it "should ignore EVENT_PORTFOLIO_TRANSFER_DENIED" do
        response.result[event_type_key] = described_class::EVENT_PORTFOLIO_TRANSFER_DENIED
        expect(product).not_to receive(:deny_takeover!)
        event_listener.process_event(response.result, product, mailer_double)
      end

      it "should ignore EVENT_PORTFOLIO_TRANSFER_CORRESPONDENCE" do
        response.result[event_type_key] = described_class::EVENT_PORTFOLIO_TRANSFER_CORRESPONDENCE
        expect(product).not_to receive(:receive_correspondence!)
        event_listener.process_event(response.result, product, mailer_double)
      end
    end
  end
end
