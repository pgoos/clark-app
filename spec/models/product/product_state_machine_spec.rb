
require "rails_helper"

RSpec.describe Product, type: :model do
  subject { product }

  let(:product) {
    build(:product)
  }

  it {
    expect(subject).to be_valid
  }

  # State Machine
  describe "state machine" do
    shared_examples "cancelable" do
      it "can not be terminated by customer if it's sold by us" do
        allow(product).to receive(:sold_by_us?).and_return(true)
        expect(product.customer_terminated).to eq(false)
      end

      it "can be terminated by customer if it's not sold by others" do
        allow(product).to receive(:sold_by_us?).and_return(false)
        expect(product.customer_terminated).to eq(true)
      end
    end

    context "when transition via customer_terminated to terminated" do
      let(:now) { Time.zone.now }
      let(:product) { create(:product, contract_ended_at: now, mandate: build(:mandate)) }

      it "changes contract end date to yesterday given product not sold by other" do
        allow(product).to receive(:sold_by_us?).and_return(false)

        product.customer_terminated

        expect(product).to be_terminated
        expect(product.contract_ended_at < now).to be_truthy
      end

      it "should not change contract end date to yesterday given product sold by other" do
        allow(product).to receive(:sold_by_us?).and_return(true)

        product.customer_terminated

        expect(product).to be_details_available
        expect(product.contract_ended_at).to eq(now)
      end
    end

    context "when customer_provided" do
      let(:product) { build(:product, state: :customer_provided, analysis_state: :details_missing, mandate: build(:mandate)) }

      it { expect(product).to be_customer_provided }
      it { expect(product).to be_valid }

      it "can be transitioned to details_available" do
        product.save!
        product.details_saved
        expect(product).to be_details_available
      end

      it "can be transitioned to terminated" do
        product.customer_terminated
        expect(product).to be_persisted
        expect(product).to be_terminated
      end
    end

    context "with initial state/details_available" do
      let(:product) { build(:product, mandate: build(:mandate)) }

      it "has details available" do
        expect(product).to be_details_available
      end

      it "can be terminated" do
        expect(product.terminate).to eq(true)
        expect(product).to be_terminated
      end

      it "can be intended to be terminated" do
        expect(product.intend_to_terminate).to eq(true)
        expect(product).to be_termination_pending
      end

      it "can be requested to be taken over" do
        expect(product.takeover_requested_at).to be nil

        expect(product.request_takeover).to eq(true)
        product.reload

        expect(product).to be_takeover_requested
        expect(product.takeover_requested_at).not_to be nil
      end

      it "does not transition to other states" do
        expect(product.cancel).to eq(false)
        expect(product.intend_to_order).to eq(false)
        expect(product.take_under_management).to eq(false)
        expect(product.order).to eq(false)
        expect(product.reset_to_under_management).to eq(false)
        expect(product.reset_to_details_available).to eq(false)
        expect(product.deny_takeover).to eq(false)
        expect(product.receive_correspondence).to eq(false)
        expect(product.customer_canceled).to eq(false)
      end

      it_behaves_like "cancelable"
    end

    context "with state: takeover_requested" do
      let(:product) { build(:product, mandate: build(:mandate), state: "takeover_requested") }

      it "has takeover_requested" do
        expect(product).to be_takeover_requested
      end

      it "can be taken under management" do
        expect(product.take_under_management).to eq(true)
        expect(product).to be_under_management
      end

      it "can be terminated" do
        expect(product.terminate).to eq(true)
        expect(product).to be_terminated
      end

      it "can be intended to be terminated" do
        expect(product.intend_to_terminate).to eq(true)
        expect(product).to be_termination_pending
      end

      it "can be denied to be taken over" do
        expect(product.deny_takeover).to eq(true)
        expect(product).to be_takeover_denied
      end

      it "can become correspondence contract" do
        expect(product.receive_correspondence).to eq(true)
        expect(product).to be_correspondence
      end

      it "does not transition to other states" do
        expect(product.request_takeover).to eq(false)
        expect(product.intend_to_order).to eq(false)
        expect(product.cancel).to eq(false)
        expect(product.order).to eq(false)
        expect(product.reset_to_under_management).to eq(false)
        expect(product.reset_to_details_available).to eq(false)
        expect(product.customer_canceled).to eq(false)
      end

      it_behaves_like "cancelable"
    end

    context "with state: under_management" do
      let(:product) { build(:product, mandate: build(:mandate), state: "under_management") }

      it "is under_management" do
        expect(product).to be_under_management
      end

      it "can be terminated" do
        expect(product.terminate).to eq(true)
        expect(product).to be_terminated
      end

      it "can be intended to be terminated" do
        expect(product.intend_to_terminate).to eq(true)
        expect(product).to be_termination_pending
      end

      it "can be denied to be taken over" do
        expect(product.deny_takeover).to eq(true)
        expect(product).to be_takeover_denied
      end

      it "can become correspondence contract" do
        expect(product.receive_correspondence).to eq(true)
        expect(product).to be_correspondence
      end

      it "can not be canceled by customer if it does not match the conditions of cancellation" do
        allow(product).to receive(:can_be_canceled_by_customer?).and_return(false)
        expect(product.customer_canceled).to eq(false)
      end

      it "can be canceled by customer if it matches the conditions of cancellation" do
        allow(product).to receive(:can_be_canceled_by_customer?).and_return(true)
        expect(product.customer_canceled).to eq(true)
        expect(product).to be_canceled_by_customer
      end

      it "does not transition to other states" do
        expect(product.request_takeover).to eq(false)
        expect(product.intend_to_order).to eq(false)
        expect(product.take_under_management).to eq(false)
        expect(product.cancel).to eq(false)
        expect(product.order).to eq(false)
        expect(product.reset_to_under_management).to eq(false)
        expect(product.reset_to_details_available).to eq(false)
      end

      it_behaves_like "cancelable"
    end

    context "with state: offered" do
      let(:product) { build(:product, mandate: build(:mandate), state: "offered") }

      it "has offered state" do
        expect(product).to be_offered
      end

      it "can be intended to be ordered" do
        expect(product.intend_to_order).to eq(true)
        expect(product).to be_order_pending
      end

      it "can be canceled" do
        expect(product.cancel).to eq(true)
        expect(product).to be_canceled
      end

      it "does not transition to other states" do
        expect(product.request_takeover).to eq(false)
        expect(product.intend_to_terminate).to eq(false)
        expect(product.take_under_management).to eq(false)
        expect(product.terminate).to eq(false)
        expect(product.order).to eq(false)
        expect(product.reset_to_under_management).to eq(false)
        expect(product.reset_to_details_available).to eq(false)
        expect(product.deny_takeover).to eq(false)
        expect(product.receive_correspondence).to eq(false)
        expect(product.customer_canceled).to eq(false)
      end

      it "can be canceled by customer" do
        allow(product).to receive(:sold_by_others?).and_return(true)
        expect(product.customer_canceled).to eq(false)
      end
    end

    context "with state: order_pending" do
      let(:product) { build(:product, mandate: build(:mandate), state: "order_pending") }

      it "has order_pending state" do
        expect(product).to be_order_pending
      end

      context "with advisory_documentation" do
        let!(:document) do
          create(:document, documentable: product, document_type: DocumentType.advisory_documentation)
        end

        it "can be ordered" do
          expect(product.order).to eq(true)
          expect(product).to be_ordered
        end

        it "finishes opportunity" do
          expect(product).to receive(:finish_opportunity)
          product.order
        end

        context "with invalid product" do
          let(:offer) { build(:offer) }
          let!(:opportunity) { build(:opportunity, offer: offer, state: :offer_phase) }

          before do
            product.offered_by = offer
            product.plan = nil
          end

          it "does call complete on opportunity" do
            product.order
            expect(opportunity).not_to receive(:complete)
          end
        end
      end

      context "without advisory_documentation" do
        it "can not be ordered" do
          expect(product.order).to eq(false)
          expect(product).to be_order_pending
        end

        it "does not finish opportunity" do
          expect(product).not_to receive(:finish_opportunity)
          product.order
        end
      end

      it "can be canceled" do
        expect(product.cancel).to eq(true)
        expect(product).to be_canceled
      end

      it "does not transition to other states" do
        expect(product.request_takeover).to eq(false)
        expect(product.take_under_management).to eq(false)
        expect(product.intend_to_terminate).to eq(false)
        expect(product.terminate).to eq(false)
        expect(product.intend_to_order).to eq(false)
        expect(product.reset_to_under_management).to eq(false)
        expect(product.reset_to_details_available).to eq(false)
        expect(product.deny_takeover).to eq(false)
        expect(product.receive_correspondence).to eq(false)
        expect(product.customer_canceled).to eq(false)
      end

      it_behaves_like "cancelable"
    end

    context "with state: ordered" do
      let(:product) { build(:product, mandate: build(:mandate), state: "ordered") }

      it "has ordered state" do
        expect(product).to be_ordered
      end

      it "can be canceled" do
        expect(product.cancel).to eq(true)
        expect(product).to be_canceled
      end

      it "can be taken under management" do
        expect(product.take_under_management).to eq(true)
        expect(product).to be_under_management
      end

      it "does not transition to other states" do
        expect(product.request_takeover).to eq(false)
        expect(product.intend_to_terminate).to eq(false)
        expect(product.terminate).to eq(false)
        expect(product.intend_to_order).to eq(false)
        expect(product.order).to eq(false)
        expect(product.reset_to_under_management).to eq(false)
        expect(product.reset_to_details_available).to eq(false)
        expect(product.deny_takeover).to eq(false)
        expect(product.receive_correspondence).to eq(false)
        expect(product.customer_canceled).to eq(false)
      end

      it "can be canceled by customer" do
        allow(product).to receive(:sold_by_others?).and_return(true)
        expect(product.customer_canceled).to eq(false)
      end
    end

    context "with state: termination_pending" do
      let(:product) { build(:product, mandate: build(:mandate), state: "termination_pending") }

      it "has termination_pending state" do
        expect(product).to be_termination_pending
      end

      it "can be terminated" do
        expect(product.terminate).to eq(true)
        expect(product).to be_terminated
      end

      it "can be reset to details available" do
        expect(product.reset_to_details_available).to eq(true)
        expect(product).to be_details_available
      end

      it "can be reset to under management" do
        expect(product.reset_to_under_management).to eq(true)
        expect(product).to be_under_management
      end

      it "does not transition to other states" do
        expect(product.request_takeover).to eq(false)
        expect(product.intend_to_terminate).to eq(false)
        expect(product.cancel).to eq(false)
        expect(product.intend_to_order).to eq(false)
        expect(product.order).to eq(false)
        expect(product.take_under_management).to eq(false)
        expect(product.deny_takeover).to eq(false)
        expect(product.receive_correspondence).to eq(false)
        expect(product.customer_canceled).to eq(false)
      end
    end

    context "with state: terminated" do
      let(:product) { build(:product, mandate: build(:mandate), state: "terminated") }

      it "has terminated state" do
        expect(product).to be_terminated
      end

      it "does not transition to other states" do
        expect(product.request_takeover).to eq(false)
        expect(product.intend_to_terminate).to eq(false)
        expect(product.terminate).to eq(false)
        expect(product.cancel).to eq(false)
        expect(product.intend_to_order).to eq(false)
        expect(product.order).to eq(false)
        expect(product.take_under_management).to eq(false)
        expect(product.reset_to_under_management).to eq(false)
        expect(product.reset_to_details_available).to eq(false)
        expect(product.deny_takeover).to eq(false)
        expect(product.receive_correspondence).to eq(false)
        expect(product.customer_canceled).to eq(false)
      end

      it_behaves_like "cancelable"
    end

    context "with state: canceled" do
      let(:product) { build(:product, mandate: build(:mandate), state: "canceled") }

      it "has canceled state" do
        expect(product).to be_canceled
      end

      it "does not transition to other states" do
        expect(product.request_takeover).to eq(false)
        expect(product.intend_to_terminate).to eq(false)
        expect(product.terminate).to eq(false)
        expect(product.cancel).to eq(false)
        expect(product.intend_to_order).to eq(false)
        expect(product.order).to eq(false)
        expect(product.take_under_management).to eq(false)
        expect(product.reset_to_under_management).to eq(false)
        expect(product.reset_to_details_available).to eq(false)
        expect(product.deny_takeover).to eq(false)
        expect(product.receive_correspondence).to eq(false)
        expect(product.customer_canceled).to eq(false)
      end

      it "can be canceled by customer" do
        allow(product).to receive(:sold_by_others?).and_return(true)
        expect(product.customer_canceled).to eq(false)
      end
    end

    context "with state: takeover_denied" do
      let(:product) { build(:product, mandate: build(:mandate), state: "takeover_denied") }

      it "has takeover_denied state" do
        expect(product).to be_takeover_denied
      end

      it "can be taken under management" do
        expect(product.take_under_management).to eq(true)
        expect(product).to be_under_management
      end

      it "can be terminated" do
        expect(product.terminate).to eq(true)
        expect(product).to be_terminated
      end

      it "can be intended to be terminated" do
        expect(product.intend_to_terminate).to eq(true)
        expect(product).to be_termination_pending
      end

      it "does not transition to other states" do
        expect(product.request_takeover).to eq(false)
        expect(product.cancel).to eq(false)
        expect(product.intend_to_order).to eq(false)
        expect(product.order).to eq(false)
        expect(product.reset_to_under_management).to eq(false)
        expect(product.reset_to_details_available).to eq(false)
        expect(product.cancel).to eq(false)
        expect(product.receive_correspondence).to eq(false)
        expect(product.customer_canceled).to eq(false)
      end
    end

    context "with state: correspondence" do
      let(:product) { build(:product, mandate: build(:mandate), state: "correspondence") }

      it "has correspondence state" do
        expect(product).to be_correspondence
      end

      it "can be taken under management" do
        expect(product.take_under_management).to eq(true)
        expect(product).to be_under_management
      end

      it "can be denied to be taken over" do
        expect(product.deny_takeover).to eq(true)
        expect(product).to be_takeover_denied
      end

      it "can be terminated" do
        expect(product.terminate).to eq(true)
        expect(product).to be_terminated
      end

      it "can be intended to be terminated" do
        expect(product.intend_to_terminate).to eq(true)
        expect(product).to be_termination_pending
      end

      it "does not transition to other states" do
        expect(product.request_takeover).to eq(false)
        expect(product.cancel).to eq(false)
        expect(product.intend_to_order).to eq(false)
        expect(product.order).to eq(false)
        expect(product.reset_to_under_management).to eq(false)
        expect(product.reset_to_details_available).to eq(false)
        expect(product.cancel).to eq(false)
        expect(product.customer_canceled).to eq(false)
      end

      it_behaves_like "cancelable"
    end
  end
end
