require "rails_helper"

require Rails.root.join("app", "composites", "customer", "entities", "customer")

RSpec.describe Domain::Messenger::AutomatedFirstMessage do
  let(:current_user) { create(:user) }
  let(:mandate) { create(:mandate) }
  let!(:admin) { create(:admin) }
  # Ahoy tracking controller
  let(:controller) { Ahoy::EventsController.new }
  let(:ahoy_tracker) { Ahoy::Tracker.new(controller: controller) }
  let(:ahoy_store) { ahoy_tracker.instance_variable_get(:@store) }
  let(:visit_token) { "c1b6324a-bcb4-4ce8-b44c-88493f4d912a" }
  let(:visitor_token) { "668337f0-8707-426b-a797-adcb5348640e" }

  before do
    env_double = {"warden" => double(user: nil)}
    mock_request = OpenStruct.new(headers: {}, cookies: {}, params: {}, env: env_double)
    allow(controller).to receive(:request).and_return(mock_request)
    allow(controller).to receive(:current_user).and_return(current_user)
    allow(Features).to receive(:active?).and_return(false)
    allow(Features).to receive(:active?).with(Features::MESSENGER).and_return(true)
  end

  context "sending WAITING_TIME_SATISFACTION_MESSAGE logic" do
    context "with an incomplete mandate" do
      before do
        mandate.update(state: "in_creation")
        @subject = described_class.new(mandate)
      end

      it "it does not send the message" do
        @subject.trigger
        expect(Interaction.last.identifier).not_to eq(described_class::WAITING_TIME_SATISFACTION_MESSAGE)
      end
    end

    context "with a complete mandate" do
      before do
        mandate.update(state: "created")
        @subject = described_class.new(mandate)
      end

      context "on the waiting time variant" do
        before do
          current_user.mandate = mandate
          current_user.save
          ahoy_store.track_visit({visit_token: visit_token, visitor_token: visitor_token})
          ahoy_store.track_event(name: "waitingtime_satisfaction", properties: {value: "variation_on"},
                                  event_id: "6d5fcf55-782f-6464-b56a-142d93053415", visit_token: visit_token)
        end

        context "having not sent the message before" do

          context "with a mark as read event" do
            let(:new_subject) { described_class.new(mandate, :mark_as_read) }

            it "it should not sent the message" do
              expect {
                new_subject.trigger
              }.not_to change { Interaction.count }
            end
          end

          context "with not marked as read" do
            it "it sends the message" do
              expect {
                @subject.trigger
              }.to change { Interaction.count }.by(1)
              expect(Interaction.last.identifier).to eq(described_class::WAITING_TIME_SATISFACTION_MESSAGE)
            end

            it "it does not send the message, if out of scope" do
              mandate.update!(customer_state: Customer::Entities::Customer::MANDATE_CUSTOMER)
              expect {
                @subject.trigger
              }.not_to change { Interaction.count }
            end
          end
        end
        context "having sent the message already" do

          it "it should not sent the message" do
            @subject.trigger
            expect {
              @subject.trigger
            }.not_to change { Interaction.count }
          end
        end
      end

      context "not on the waiting time variant" do
        before do
          current_user.mandate = mandate
          current_user.save
          ahoy_store.track_event(name: "waitingtime_satisfaction", properties: {value: "variation_off"},
                                 event_id: "6d5fcf55-782f-6464-b56a-142d93053415")
        end
        it "it should send the normal congratulate message" do
          @subject.trigger
          expect(Interaction.last.identifier).to eq(described_class::CONGRATULATE_MESSAGE_NO_VOUCHER)
        end
      end
    end
  end

  context "sends CONGRATULATE_MESSAGE" do
    let(:delivery) { instance_double(OutboundChannels::Messenger::MessageDelivery) }
    let(:content)  { I18n.t("messenger.congratulations_message_no_voucher.content", name: mandate.first_name) }
    let(:metadata) do
      {
        identifier: "messenger.congratulations_message_no_voucher",
        created_by_robo: true,
        cta_text: I18n.t("messenger.congratulations_message_no_voucher.cta_text"),
        cta_link: I18n.t("messenger.congratulations_message_no_voucher.cta_link"),
        cta_section: I18n.t("messenger.congratulations_message_no_voucher.cta_section")
      }
    end

    before do
      mandate.update(state: "created")
      @subject = described_class.new(mandate)
      allow(mandate).to receive(:voucher).and_return(nil)
    end

    it "calls send_message with push option as false" do
      allow(OutboundChannels::Messenger::MessageDelivery).to receive(:new)
        .with(content, mandate, Admin.first, metadata)
        .and_return(delivery)

      allow(delivery).to receive(:send_message).with(push: false)

      @subject.trigger
      expect(delivery).to have_received(:send_message)
    end

    it "creates one message" do
      expect {
        @subject.trigger
      }.to change { Interaction.count }.by(1)
    end

    it "creates a retarget message" do
      @subject.trigger
      expect(Interaction.last.identifier).to eq(described_class::CONGRATULATE_MESSAGE_NO_VOUCHER)
    end

    it "does not create a second message of the same type" do
      @subject.trigger
      expect {
        @subject.trigger
      }.not_to change { Interaction.count }
    end

    it "it does not send the message, if out of scope" do
      mandate.update!(customer_state: Customer::Entities::Customer::MANDATE_CUSTOMER)
      expect {
        @subject.trigger
      }.not_to change { Interaction.count }
    end

    context "when mandate has voucher" do
      let (:voucher) { double("voucher") }
      before do
        allow(mandate).to receive(:voucher).and_return(voucher)
      end

      it "doesn't send congratulations no voucher if the mandate has voucher" do
        @subject.trigger
        expect(Interaction.last.identifier).not_to eq(described_class::CONGRATULATE_MESSAGE_NO_VOUCHER)
      end

      it "sends congratulations with voucher if the mandate has voucher" do
        @subject.trigger
        expect(Interaction.last.identifier).to eq(described_class::CONGRATULATE_MESSAGE_WITH_VOUCHER)
      end
    end
  end

  context  "sends EXPLAIN_MESSAGE" do
    before do
      mandate.update(state: "in_creation", info: {wizard_steps: []})
      @subject = described_class.new(mandate)
    end

    it "creates one message" do
      expect {
        @subject.trigger
      }.to change { Interaction.count }.by(1)
    end

    it "creates a retarget message" do
      @subject.trigger
      expect(Interaction.last.identifier).to eq(described_class::EXPLAIN_MESSAGE)
    end

    it "does not create a second message of the same type" do
      @subject.trigger
      expect {
        @subject.trigger
      }.not_to change { Interaction.count }
    end

    context "customer status is set to mandate_customer" do
      before { mandate.update!(customer_state: Customer::Entities::Customer::MANDATE_CUSTOMER) }

      it "does not send the message" do
        expect { @subject.trigger }.not_to change(Interaction, :count)
      end
    end
  end

  context "sends RETARGET_MESSAGE" do
    before do
      mandate.update(state: "in_creation", info: {wizard_steps: ["targeting"]})
      @subject = described_class.new(mandate)
    end

    it "creates one message" do
      expect {
        @subject.trigger
      }.to change { Interaction.count }.by(1)
    end

    it "creates a retarget message" do
      @subject.trigger
      expect(Interaction.last.identifier).to eq(described_class::RETARGET_MESSAGE)
    end

    it "does not create a second message of the same type" do
      @subject.trigger
      expect {
        @subject.trigger
      }.not_to change { Interaction.count }
    end

    it "it does not send the message, if out of scope" do
      mandate.update!(customer_state: Customer::Entities::Customer::MANDATE_CUSTOMER)
      expect {
        @subject.trigger
      }.not_to change { Interaction.count }
    end
  end
end
