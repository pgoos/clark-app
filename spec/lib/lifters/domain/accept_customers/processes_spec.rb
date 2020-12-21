# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::AcceptCustomers::Processes do
  before { create(:category_gkv) }

  def create_mandate
    create(:mandate, user: create(:user), state: "created")
  end

  describe "loading data" do
    it "should load all created mandates" do
      mandates = [create_mandate, create_mandate]
      expect(described_class.acceptance_candidates).to match_array(mandates)
    end

    it "should not load mandates of states different to 'created'" do
      Mandate.state_machine.states.map(&:name).except(:created).each do |other_state|
        create(:mandate, state: other_state.to_s, phone: "+491234567890", gender: "male")
      end
      expect(described_class.acceptance_candidates).to be_empty
    end

    context "#request_corrections_process" do
      let(:mandate) { create_mandate }

      it "changes mandate state" do
        described_class.request_corrections_process(mandate)
        mandate.reload
        expect(mandate).to be_in_creation
      end

      it "sends email to the customer" do
        message = n_double("message('sends email to the customer')")
        expect(message).to receive(:deliver_later)

        allow(MandateMailer).to receive(:request_corrections).with(mandate).and_return(message)
        described_class.request_corrections_process(mandate)
      end
    end

    context "#accept_customer_process", integration: true do
      let(:mandate)             { create_mandate }
      let(:blacklisted_company) { create(:company, inquiry_blacklisted: true) }
      let(:gkv_company)         { create(:gkv_company, inquiry_blacklisted: false) }

      let(:company) do
        create(:company, ident: "generic", inquiry_blacklisted: false, mandates_email: "FOO@BAR.COM")
      end

      before do
        allow(Features).to receive(:active?).and_call_original
        allow(Features).to receive(:active?).with(Features::INQUIRY_EMAILS).and_return(true)
      end

      def create_inquiry_in_creation(company)
        create(:inquiry, mandate: mandate, company: company, state: "in_creation")
      end

      it "should accept the customer and send allowed inquiries" do
        inquiry           = create_inquiry_in_creation(company)
        blacklist_inquiry = create_inquiry_in_creation(blacklisted_company)
        gkv_inquiry       = create_inquiry_in_creation(gkv_company)

        message = n_double("message('should accept the customer and send allowed inquiries')")
        expect(message).to receive(:deliver_now)

        allow(InquiryMailer)
          .to receive(:insurance_request)
          .with(
            inquiry: inquiry,
            categories: inquiry.categories,
            ident: company.ident,
            insurer_mandates_email: "FOO@BAR.COM"
          )
          .and_return(message)

        described_class.accept_customer_process(mandate)
        mandate.reload
        inquiry.reload
        blacklist_inquiry.reload
        gkv_inquiry.reload

        expect(mandate).to be_accepted
        expect(mandate.active_address).to be_accepted
        expect(inquiry).to be_contacted
        expect(blacklist_inquiry).to be_pending
        expect(gkv_inquiry).to be_pending
      end

      it "shouldn't send the inquiry emails if feature switch for inquiry emails is turned off" do
        allow(Features).to receive(:active?).with(Features::INQUIRY_EMAILS).and_return(false)
        inquiry = create_inquiry_in_creation(company)
        expect(InquiryMailer).not_to receive(:insurance_request)
        described_class.accept_customer_process(mandate)
        inquiry.reload
        expect(inquiry).to be_pending
      end

      it "should create the gkv product creation job" do
        create_inquiry_in_creation(gkv_company)

        Timecop.freeze do
          expected_time = Time.zone.today.beginning_of_day.advance(days: 2, hours: 8)
          chain_double = n_double("gkv_job")
          expect(CreateGkvProductJob)
            .to receive(:set).with(wait_until: expected_time).and_return(chain_double)
          expect(chain_double).to receive(:perform_later).with(mandate_id: mandate.id)
          described_class.accept_customer_process(mandate)
        end
      end

      it "should schedule the gkv job creation even without inquiries" do
        # The reason is the asynchronous character of the job. A customer might add the gkv
        # inquiry in the time interval between acceptance and job execution.
        Timecop.freeze do
          expected_time = Time.zone.today.beginning_of_day.advance(days: 2, hours: 8)
          chain_double = n_double("gkv_job")
          expect(CreateGkvProductJob)
            .to receive(:set).with(wait_until: expected_time).and_return(chain_double)
          expect(chain_double).to receive(:perform_later).with(mandate_id: mandate.id)
          described_class.accept_customer_process(mandate)
        end
      end

      it "should not create the welcome booking job for a Miles&More customer" do
        mandate = create(
          :mandate,
          :mam_with_status,
          :accepted,
          state: "created"
        )
        allow(mandate).to receive(:mam_enabled?).and_return(true)
        Timecop.freeze do
          expected_time = Time.zone.now.advance(hours: 24)
          chain_double = n_double("mam_job")
          expect(MamCreditWelcomeMilesJob)
            .not_to receive(:set)
          expect(chain_double).not_to receive(:perform_later)
          described_class.accept_customer_process(mandate)
        end
      end
    end
  end
end
