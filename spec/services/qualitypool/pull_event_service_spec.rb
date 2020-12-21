# frozen_string_literal: true

require "rails_helper"
require "services/qualitypool/event_listeners/event_fixtures"

RSpec.describe Qualitypool::PullEventService do

  include_context "event fixtures"

  subject(:pull_event_service) { Qualitypool::PullEventService.new(service_double, mailer_double) }
  let(:remote_next) { Qualitypool::PullEventService::REMOTE_METHOD_NEXT_EVENT }

  before do
    allow(service_double).to receive(:execute_rpc_call).with(remote_next, payload)
      .and_return(response)
    allow(Product).to receive(:find_by).with(qualitypool_id: remote_product_id).and_return(product)
  end

  context "business event" do
    before do
      allow(described_class).to receive(:listeners).and_return({})
    end

    it "returns 1 if it has an upfollowing event to 0" do
      allow(BusinessEvent).to receive(:audit).with(product, String, Hash)
      event_id = pull_event_service.handle_quality_pool_event(0)
      expect(event_id).to eq(1)
    end

    it "returns n+1 if it has an upfollowing event to n" do
      previous_id, new_id = payload_and_response_with_later_ids(payload, response)
      allow(BusinessEvent).to receive(:audit).with(product, String, Hash)
      event_id = pull_event_service.handle_quality_pool_event(previous_id)
      expect(event_id).to eq(new_id)
    end

    it "does not audit if it has no upfollowing event to the previous one" do
      allow(response).to receive(:result).and_return(nil)
      expect(BusinessEvent).not_to receive(:audit)
      pull_event_service.handle_quality_pool_event(0)
    end

    it "does not audit if it has no upfollowing event to the previous one" do
      allow(response).to receive(:result).and_return(nil)
      expect(BusinessEvent).not_to receive(:audit)
      pull_event_service.handle_quality_pool_event(0)
    end

    it "returns nil if it has no upfollowing event to the previous one" do
      allow(response).to receive(:result).and_return(nil)
      event_id = pull_event_service.handle_quality_pool_event(0)
      expect(event_id).to be_nil
    end

    it "creates a business event for the related local object of the last seen event" do
      expect(BusinessEvent).to receive(:audit).with(product, String, Hash)
      pull_event_service.handle_quality_pool_event(0)
    end

    it "creates a business event containing the id of the last seen event" do
      expect(BusinessEvent).to receive(:audit)
        .with(product, String, hash_including(event_pulled: 1))
      pull_event_service.handle_quality_pool_event(0)
    end

    it "creates a business event with the last event's id for an arbitrary previous event id" do
      previous_id, new_id = payload_and_response_with_later_ids(payload, response)

      expect(BusinessEvent).to receive(:audit)
        .with(product, String, hash_including(event_pulled: new_id))
      pull_event_service.handle_quality_pool_event(previous_id)
    end

    it "remembers the action handle_quality_pool_event in the business event" do
      expect(BusinessEvent).to receive(:audit).with(product, "handle_quality_pool_event", Hash)
      pull_event_service.handle_quality_pool_event(0)
    end

    it "ignores the DokumentID key" do
      object = response.result[:Fachobjekte]
      object[:DokumentID] = 743_907_118

      allow(BusinessEvent).to receive(:audit).with(product, String, Hash)
      event_id = pull_event_service.handle_quality_pool_event(0)
      expect(event_id).to eq(1)
    end

    it "ignores the PersonID key" do
      object = response.result[:Fachobjekte]
      object[:PersonID] = 111_222_333

      allow(BusinessEvent).to receive(:audit).with(product, String, Hash)
      event_id = pull_event_service.handle_quality_pool_event(0)
      expect(event_id).to eq(1)
    end
  end

  context "catch_up_pool_events", :business_events do
    let(:qualitypool_id) { 1 }
    let(:event_id) { 2 }
    let!(:product) { create(:product, state: :takeover_requested, qualitypool_id: remote_product_id) }
    let!(:admin) { create(:admin) }

    let(:first_payload) { example_payload(0) }
    let(:first_response) { example_response(remote_product_id, event_id) }

    let(:second_payload) { example_payload(event_id) }
    let(:second_response) { OpenStruct.new(result: nil) }

    before do
      allow(Product).to receive(:find_by).and_call_original

      transfer_success = Qualitypool::EventListeners::PortfolioTransferStateListener::EVENT_PORTFOLIO_TRANSFER_SUCCESS
      first_response.result[described_class::EVENT_TYPE_KEY] = transfer_success

      allow(service_double).to receive(:execute_rpc_call).with(remote_next, first_payload).and_return(first_response)
      allow(service_double).to receive(:execute_rpc_call).with(remote_next, second_payload).and_return(second_response)
    end

    it "stops processing", :business_events do
      ids = pull_event_service.catch_up_pool_events
      expect(ids).to eq [2]
      expect(product.reload).to be_under_management
    end
  end

  context "listeners" do
    let(:transaction_portfolio_transfer_success) { "sample business transaction name" }
    let(:transaction_other) { "OtherBusinessTransaction" }
    let(:class_name_of_listener) { "ClassNameOfListener" }
    let(:listener_1) { double("qualitypool_listener_1", name: class_name_of_listener) }
    let(:listener_2) { double("qualitypool_listener_2", name: class_name_of_listener) }

    before do
      allow(BusinessEvent).to receive(:audit).with(product, "handle_quality_pool_event", Hash)
    end

    it "passes the event to the first listener" do
      allow(described_class).to receive(:listeners).and_return(
        transaction_portfolio_transfer_success => [listener_1]
      )
      expect(listener_1).to receive(:process_event).with(response.result, product, mailer_double)
      pull_event_service.handle_quality_pool_event
    end

    it "passes the event to the tailing listeners for the same business transaction" do
      allow(described_class).to receive(:listeners).and_return(
        transaction_portfolio_transfer_success => [listener_1, listener_2]
      )
      expect(listener_1).to receive(:process_event).with(response.result, product, mailer_double)
      expect(listener_2).to receive(:process_event).with(response.result, product, mailer_double)
      pull_event_service.handle_quality_pool_event
    end

    it "process listeners for a different business transaction" do
      response.result[Qualitypool::PullEventService::EVENT_TYPE_KEY] = transaction_other

      allow(described_class).to receive(:listeners).and_return(
        transaction_other => [listener_1, listener_2]
      )

      expect(listener_1).to receive(:process_event).with(response.result, product, mailer_double)
      expect(listener_2).to receive(:process_event).with(response.result, product, mailer_double)

      pull_event_service.handle_quality_pool_event
    end

    it "does not pass events to wrong listeners (see key Geschaeftsvorgang in response)" do
      response.result[Qualitypool::PullEventService::EVENT_TYPE_KEY] = transaction_other

      unwanted_listener = n_double("dummy_1")
      allow(described_class).to receive(:listeners).and_return(
        transaction_portfolio_transfer_success => [unwanted_listener],
        transaction_other                      => [listener_1]
      )

      expect(unwanted_listener).not_to receive(:process_event)
      allow(listener_1).to receive(:process_event).with(response.result, product, mailer_double)

      pull_event_service.handle_quality_pool_event
    end

    it "creates a business event and marks it as no_listeners, if no listeners were found" do
      allow(described_class).to receive(:listeners).and_return(
        transaction_portfolio_transfer_success => nil
      )

      expect(BusinessEvent).to receive(:audit)
        .with(product, String, hash_including(processed_listeners: []))

      pull_event_service.handle_quality_pool_event
    end

    it "creates a business event and adds the listeners class names, if listeners were found" do
      allow(described_class).to receive(:listeners).and_return(
        transaction_portfolio_transfer_success => [listener_1]
      )
      expect(listener_1).to receive(:process_event).with(response.result, product, mailer_double)

      expect(BusinessEvent).to receive(:audit).with(
        product,
        String,
        hash_including(processed_listeners: [class_name_of_listener])
      )

      pull_event_service.handle_quality_pool_event
    end

    it "should have valid listeners" do
      described_class.listeners.each do |business_transaction_name, listeners|
        expect(business_transaction_name).to be_a(String)
        expect(listeners).to be_an(Array)
      end
    end
  end

  context "previous event lookup" do
    let(:admin) { create(:admin) }
    let(:db_product) { create(:product) }

    before do
      BusinessEvent.audit_person = admin
      allow(Product).to receive(:find_by)
        .with(qualitypool_id: remote_product_id).and_return(db_product)
    end

    it "loads the first event, if no previous event id is found" do
      expect(BusinessEvent).to receive(:audit)
        .with(db_product, String, hash_including(event_pulled: 1))
      pull_event_service.handle_quality_pool_event
    end

    it "looks up the last event, if no event is passed in", :business_events do
      previous_id, new_id = payload_and_response_with_later_ids(payload, response)
      expect(payload[:EreignisID]).to eq(previous_id)
      BusinessEvent.audit(db_product, "handle_quality_pool_event", event_pulled: previous_id)
      BusinessEvent.audit(db_product, "handle_quality_pool_event", event_pulled: previous_id - 1)

      expect(BusinessEvent.last.action).to eq("handle_quality_pool_event")

      pull_event_service.handle_quality_pool_event

      expect(BusinessEvent.last.metadata["event_pulled"]).to eq(new_id)
    end

    it "looks up the last event in NUMERICAL order and not in lexical order", :business_events do

      ##################################################################
      # the jsonb operator ->> would return the array/map value as text
      #   => lexical ordering is applied
      # the jsonb operator -> returns the jsonb object
      #   => numerical ordering is applied
      ##################################################################

      previous_id, new_id = payload_and_response_with_later_ids(payload, response, 100)
      expect(payload[:EreignisID]).to eq(previous_id)
      BusinessEvent.audit(db_product, "handle_quality_pool_event", event_pulled: previous_id)
      BusinessEvent.audit(db_product, "handle_quality_pool_event", event_pulled: previous_id - 1)

      expect(BusinessEvent.last.action).to eq("handle_quality_pool_event")

      expect(service_double).not_to receive(:execute_rpc_call)
        .with(described_class::REMOTE_METHOD_NEXT_EVENT, EreignisID: 99)

      pull_event_service.handle_quality_pool_event

      expect(BusinessEvent.last.metadata["event_pulled"]).to eq(new_id)
    end
  end

  context "errors" do
    let(:admin) { create(:admin) }
    let(:transaction_portfolio_transfer_success) { "sample business transaction name" }
    let(:class_name_of_listener) { "ClassNameOfListener" }
    let(:listener_1) { double("qualitypool_listener_1", name: class_name_of_listener) }

    context "known errors: related object is not there" do
      before do
        BusinessEvent.audit_person = admin
        allow(Product).to receive(:find_by).with(qualitypool_id: remote_product_id).and_return(nil)
        allow(described_class).to receive(:listeners).and_return(
          transaction_portfolio_transfer_success => [listener_1]
        )
        allow(listener_1).to receive(:process_event)
          .with(response.result, nil).and_raise(StandardError)
        allow(mailer_double).to receive(:send_plain_text)
        allow(BusinessEvent).to receive(:audit)
      end

      it "should not throw an exception" do
        expect {
          pull_event_service.handle_quality_pool_event(0)
        }.not_to raise_error
      end

      it "should send an email to the team of consultants" do
        expected_message = double("-> Qualitypool::PullEventService::ObjectMissingMessage")
        message_type     = Qualitypool::PullEventService::ObjectMissingMessage
        allow(message_type).to receive(:new)
          .with(response.result, Product, remote_product_id)
          .and_return(expected_message)
        expect(mailer_double).to receive(:send_plain_text)
          .with(mail_from, mail_to, expected_message)
        pull_event_service.handle_quality_pool_event(0)
      end

      it "should write a business event with the error data" do
        previous_id, new_id = payload_and_response_with_later_ids(payload, response)
        expect(BusinessEvent).to receive(:audit).with(
          BusinessEvent.audit_person,
          "handle_quality_pool_event",
          hash_including(
            event_pulled: new_id,
            errors:       {
              event:         response.result,
              error_details: [{error: "object missing", object_type: Product.name}]
            }
          )
        )
        pull_event_service.handle_quality_pool_event(previous_id)
      end

      context "cleanup" do
        let(:ids) { payload_and_response_with_later_ids(payload, response) }
        let(:previous_id) { ids[0] }
        let(:new_id) { ids[1] }

        before do
          allow(BusinessEvent).to receive(:audit).with(
            BusinessEvent.audit_person,
            "handle_quality_pool_event",
            hash_including(
              event_pulled: new_id,
              errors:       {
                event:         response.result,
                error_details: [{error: "object missing", object_type: Product.name}]
              }
            )
          )
          pull_event_service.handle_quality_pool_event(previous_id)
        end

        it "should clear the @current_event" do
          expect(pull_event_service.instance_variable_get("@current_event".to_sym)).to be_nil
        end

        it "should clear the @objects" do
          expect(pull_event_service.instance_variable_get("@objects".to_sym)).to be_nil
        end

        it "should clear the @listener_candidates" do
          expect(pull_event_service.instance_variable_get("@listener_candidates".to_sym)).to be_nil
        end

        it "should clear the @processed" do
          expect(pull_event_service.instance_variable_get("@processed".to_sym)).to be_nil
        end

        it "should clear the known errors" do
          expect(pull_event_service.instance_variable_get("@known_errors".to_sym)).to be_empty
        end
      end
    end

    context "unknown errors" do
      let(:unknown_error_message_type) { Qualitypool::PullEventService::UnknownErrorMessage }

      before do
        allow(BusinessEvent).to receive(:audit).with(product, "handle_quality_pool_event", Hash)
        allow(mailer_double).to receive(:send_plain_text)
          .with(mail_from, mail_to, unknown_error_message_type)
      end

      it "stops processing at an error" do
        allow(described_class).to receive(:listeners).and_return(
          transaction_portfolio_transfer_success => [listener_1]
        )
        err_mess = "fake error message #{rand}"
        error = StandardError.new(err_mess)
        allow(listener_1).to receive(:process_event).with(response.result, product, mailer_double)
          .and_raise(error)

        expect {
          pull_event_service.handle_quality_pool_event
        }.to raise_error(Qualitypool::PullEventService::PullEventError, err_mess)
      end

      it "creates no business event for an unknown error" do
        allow(described_class).to receive(:listeners).and_return(
          transaction_portfolio_transfer_success => [listener_1]
        )

        err_mess = "fake error message #{rand}"
        error = StandardError.new(err_mess)
        allow(listener_1).to receive(:process_event).with(response.result, product, mailer_double)
          .and_raise(error)

        expect(BusinessEvent).not_to receive(:audit)

        expect {
          pull_event_service.handle_quality_pool_event
        }.to raise_error(Qualitypool::PullEventService::PullEventError, err_mess)
      end

      it "sends a mail for an unknown error" do
        allow(described_class).to receive(:listeners).and_return(
          transaction_portfolio_transfer_success => [listener_1]
        )
        err_mess = "fake error message #{rand}"
        error = StandardError.new(err_mess)
        allow(listener_1).to receive(:process_event).with(response.result, product, mailer_double)
          .and_raise(error)

        payload = response.result.merge("ObjectId" => product.id)

        unknown_message_double = instance_double(unknown_error_message_type)
        expect(unknown_error_message_type).to \
          receive(:new).with(payload, error.message).and_return(unknown_message_double)
        expect(mailer_double).to receive(:send_plain_text).with(mail_from, mail_to, unknown_message_double)

        expect {
          pull_event_service.handle_quality_pool_event
        }.to raise_error(Qualitypool::PullEventService::PullEventError, err_mess)
      end

      it "should raise an error, if the follow up event id is not bigger as the previous" do
        err_mess = "FATAL ERROR: Event sequence broken!"
        payload[:EreignisID] = 23
        response.result[:EreignisID] = 23
        expect {
          pull_event_service.handle_quality_pool_event(23)
        }.to raise_error(Qualitypool::PullEventService::PullEventError, err_mess)
      end

      it "should not raise an error, if the follow up event id is bigger than +1" do
        payload[:EreignisID] = 23
        response.result[:EreignisID] = 25
        expect {
          pull_event_service.handle_quality_pool_event(23)
        }.not_to raise_error
      end

      it "should not fail, if there are no listeners" do
        allow(described_class).to receive(:listeners).and_return(
          transaction_portfolio_transfer_success => nil
        )

        expect {
          pull_event_service.handle_quality_pool_event
        }.not_to raise_error
      end
    end
  end
end
