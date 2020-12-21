# frozen_string_literal: true

RSpec.shared_examples "event_publishable" do |attrs|
  let(:factory_name) { ActiveModel::Naming.singular(described_class) }
  let(:instance)     { FactoryBot.build(factory_name, attrs) }
  let(:sqs_client)   { double("Aws::SQS::Client") }

  describe "public class methods" do
    context "responds to its methods" do
      it { expect(described_class).to respond_to(:publish_event) }
    end

    context "executes methods correctly" do
      context ".publish_event" do
        before do
          allow(Features).to receive(:active?).and_return(true)
          allow(Aws::SQS::Client).to receive(:new) { sqs_client }
        end

        it "skips the event publishing to the message queue when feature is disabled" do
          allow(Features).to receive(:active?).and_return(false)
          expect(described_class.publish_event(instance, "action", "event_name")).to eq(nil)
        end

        # NOTE: Temporary fixes since the api_partners application cannot process these:
        #
        # - https://clarkteam.atlassian.net/browse/JCLARK-20372
        # - https://clarkteam.atlassian.net/browse/JCLARK-30346
        #
        # These are temporary fixes that have to be removed!
        if described_class == Product
          it "skips the event publishing to the message queue for offer generation with offered product" do
            product = create(:product, state: "offered")
            expect(Product.publish_event(product, "created", "action")).to eq(nil)
          end

          it "skips the event publishing to the message queue for offer generation with cancelled product" do
            product = create(:product, state: "canceled")
            expect(Product.publish_event(product, "created", "action")).to eq(nil)
          end

          context "#reset_to_under_management" do
            let(:product) { create(:product, state: "termination_pending") }

            it "sends an event count of nil for 'reset_to_under_management'" do
              expect(product.publish_updated_event(OpenStruct.new(event: :reset_to_under_management))).to be_nil
            end

            it "skips the state machine event 'reset_to_under_management'" do
              expect(Product).not_to receive(:publish_event).with(product, "updated", "reset_to_under_management")
              product.reset_to_under_management!
            end
          end
        end

        # Do not pubish events for revoked customers, except for the mandate itself:
        # https://clarkteam.atlassian.net/browse/JCLARK-28563
        context "revoked mandate" do
          let(:revoked_mandate) { create(:mandate, :revoked) }
          let(:sqs_client) { double("Aws::SQS::Client") }

          before do
            if described_class == InquiryCategory
              instance.inquiry.mandate = revoked_mandate
            elsif !instance.is_a?(Mandate)
              instance.mandate = revoked_mandate
            end

            revoked_mandate.valid?
            instance.valid?
          end

          if described_class != Mandate
            it "sends an event count of 0 for an entity referenced by a revoked mandate" do
              expect(instance.class.publish_event(instance, "updated", "action")).to be_nil
            end
          else
            it "sends an event count for a revoked mandate" do
              expect(Mandate.publish_event(revoked_mandate, "updated", "action")).not_to be_nil
            end
          end
        end

        it "skips the event publishing to the message queue for customers acquired by Clark" do
          expect(described_class.publish_event(instance, "action", "event_name")).to eq(0)
        end

        it "skips the event publishing to the message queue if instance delegates return nil" do
          allow(instance).to receive(:owner_ident).and_return(nil)
          allow(instance).to receive(:accessible_by).and_return(nil)
          allow(instance).to receive(:accessible_by?).and_return(nil)
          expect(described_class.publish_event(instance, "action", "event_name")).to eq(0)
        end

        it "publishes the event to the message queue for non-Clark customers" do
          allow(sqs_client).to receive(:send_message).and_return(true)
          allow(instance).to receive(:accessible_by).and_return(%w[test clark partner])
          expect(described_class.publish_event(instance, "action", "event_name")).to eq(2)
        end

        context "update event on exposable fields" do
          let(:instance_fields)  { instance.attributes.keys }
          let(:instance_payload) { described_class.event_payload(instance).as_json }
          let(:data_fields) do
            instance_payload.keys.select do |k|
              unless %i[id created_at updated_at email state].include?(k) || k.to_s.include?("_id")
                k
              end
            end
          end

          before do
            allow(instance).to receive(:accessible_by).and_return(%w[clark partner])
          end

          it "publishes the event to the message queue if exposable field was updated" do
            instance = create(factory_name, attrs)

            expect(described_class).to receive(:publish_event)
              .with(instance, "updated", "update")

            instance.update_attributes!(data_fields.first => "foo")
          end

          if described_class != Interaction::Advice
            it "skips the event publishing to the message queue if only a state was updated" do
              instance = create(factory_name, attrs)

              expect(described_class).not_to receive(:publish_event)
                .with(instance, "updated", "update")

              begin
                described_class.state_machine.events.keys.each do |event|
                  break if instance.send("#{event}!".to_sym)
                end
              rescue StateMachines::InvalidTransition => e
                puts e.message
              end
            end
          end

          it "skips the event publishing to the message queue if instance just created" do
            instance = FactoryBot.build(factory_name, attrs)

            expect(described_class).to receive(:publish_event).with(instance, "created", "create")
            expect(described_class).not_to receive(:publish_event)
              .with(instance, "updated", "update")

            instance.save
          end
        end

        context "restream entity" do
          it "re-sends the entity state when restream eantity is called" do
            instance = FactoryBot.build(factory_name, attrs)
            expect(described_class).to receive(:publish_event).with(instance, "updated", instance.try(:state))
            instance.restream_state
          end
        end
      end
    end
  end
end
