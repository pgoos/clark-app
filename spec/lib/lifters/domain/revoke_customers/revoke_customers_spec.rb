# frozen_string_literal: true

require "rails_helper"

describe Domain::RevokeCustomers::RevokeCustomerProcess do
  subject { described_class.new(mandate) }

  let(:mandate) { build(:mandate, state: :accepted) }

  describe "#revoke" do
    context "mandate already revoked" do
      before do
        allow(mandate).to receive(:revoked?).and_return(true)
      end

      it "should return false when mandate" do
        expect(subject.revoke).to be false
      end
    end

    context "mandate is not revoked" do
      before do
        allow(mandate).to receive(:revoked?).and_return(false)
      end

      it "should return true after successful revoke" do
        mandate.save!
        expect(subject.revoke).to be true
      end
    end
  end

  describe "#send_revokation_email" do
    shared_examples "acquired by Clark accepted mandate" do
      before do
        allow(mandate).to receive(:accepted?).and_return(true)
        allow(mandate).to receive(:acquired_by?).with("n26").and_return(false)
      end

      it "should send revoke customer mailer" do
        expect(MandateMailer).to receive_message_chain(:revoke_customer, :deliver_later)

        subject.send_revokation_email
      end
    end

    shared_examples "acquired by Clark not accepted mandate" do
      before do
        allow(mandate).to receive(:accepted?).and_return(false)
        allow(mandate).to receive(:acquired_by?).with("n26").and_return(false)
      end

      it "should send revoke not accepted customer email" do
        expect(MandateMailer).to receive_message_chain(:revoke_not_accepted_customer, :deliver_later)

        subject.send_revokation_email
      end
    end

    context "mandate is acquired by Clark" do
      before do
        allow(mandate).to receive(:acquired_by_partner?).and_return(false)
        allow(mandate).to receive(:acquired_by?).with("marlburg").and_return(false)
      end

      it_behaves_like "acquired by Clark accepted mandate"
      it_behaves_like "acquired by Clark not accepted mandate"
    end

    context "mandate is acquired by Malburg" do
      before do
        allow(mandate).to receive(:acquired_by_partner?).and_return(true)
        allow(mandate).to receive(:acquired_by?).with("marlburg").and_return(true)
      end

      it_behaves_like "acquired by Clark accepted mandate"
      it_behaves_like "acquired by Clark not accepted mandate"
    end

    context "mandate is acquired by a partner that is neither marlburg nor n26" do
      before do
        allow(mandate).to receive(:acquired_by_partner?).and_return(true)
        allow(mandate).to receive(:acquired_by?).and_return(false)
      end

      it "should send revoke partner customer mailer" do
        expect(MandateMailer).to receive_message_chain(:revoke_partner_customer, :deliver_later)

        subject.send_revokation_email
      end

      context "when n26" do
        before do
          allow(mandate).to receive(:acquired_by?).with("n26").and_return(true)
        end

        it "should send revoke N26 customer mailer" do
          expect(MandateMailer).to receive_message_chain(:revoke_n26_customer, :deliver_later)

          subject.send_revokation_email
        end
      end
    end
  end
end
