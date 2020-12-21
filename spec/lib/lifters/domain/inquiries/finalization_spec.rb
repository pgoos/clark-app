# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Inquiries::Finalization do
  subject { described_class.new(inquiry, cancellation_config) }

  let(:inquiry_id) { (rand * 100).round + 1 }
  let(:inquiry) { instance_double(Inquiry, id: inquiry_id, mandate_acquired_by_partner?: false) }
  let(:cancellation_config) { {custom_cancel_reason: "custom reason"} }
  let(:sample_cause) { "contract_not_found" }

  let(:messenger_class) { OutboundChannels::Messenger::TransactionalMessenger }
  let(:mail) { double("generic-cancellation-mail") }

  # rubocop:disable Metrics/AbcSize
  def mock_inquiry_category(id, traits=[:in_progress])
    inquiry_category = build_stubbed(
      :inquiry_category,
      :shallow,
      *traits,
      id: id
    )
    allow(inquiry_category).to receive(:mandate_accepted?).and_return(true)
    allow(inquiry_category).to receive(:is_a?).with(any_args).and_return(false)
    allow(inquiry_category).to receive(:is_a?).with(InquiryCategory).and_return(true)
    allow(inquiry_category).to receive(:mandate_acquired_by_partner?).and_return(false)
    inquiry_category
  end
  # rubocop:enable Metrics/AbcSize

  def configure_category_cancelled(inquiry_category)
    allow(inquiry_category).to receive(:cancelled?).and_return(true)

    allow(inquiry_category).to receive(:in_progress?).and_return(false)
    allow(inquiry_category).to receive(:completed?).and_return(false)
  end

  def configure_category_completed(inquiry_category)
    allow(inquiry_category).to receive(:completed?).and_return(true)

    allow(inquiry_category).to receive(:in_progress?).and_return(false)
    allow(inquiry_category).to receive(:cancelled?).and_return(false)
  end

  def connect_inquiry_category(inquiry, inquiry_categories)
    allow(inquiry).to receive(:inquiry_categories).and_return(inquiry_categories)
  end

  before do
    allow(InquiryCategoryMailer)
      .to receive(:inquiry_categories_cancelled)
      .with(any_args)
      .and_return(mail)
    allow(mail).to receive(:deliver_now)
    allow(messenger_class).to receive(:inquiry_categories_cancelled).with(any_args)
  end

  context "cancellation" do
    let(:inquiry_category_1) { mock_inquiry_category(1) }
    let(:inquiry_category_2) { mock_inquiry_category(2) }

    before do
      connect_inquiry_category(inquiry, [inquiry_category_1, inquiry_category_2])

      allow(inquiry).to receive(:cancellable?).and_return(true)
      allow(inquiry).to receive(:cancel!)
    end

    context "when category is already cancelled" do
      let(:inquiry_category_1) { mock_inquiry_category(1, :contract_not_found) }

      it "should not cancel the category" do
        cancellation_config[1] = sample_cause

        expect(inquiry_category_1).not_to receive("cancel_because_#{sample_cause}!")

        subject.perform_available_cancellations!
      end

      context "when customer initiates cancellation" do
        let(:sample_cause) { :cancelled_by_customer }

        it "should cancel the category again on behalf of customer" do
          cancellation_config[1] = sample_cause

          expect(inquiry_category_1).to receive("cancel_because_cancelled_by_customer!")

          subject.perform_available_cancellations!
        end
      end
    end

    it "should cancel the inquiry, if no categories can be found for it" do
      allow(inquiry).to receive(:inquiry_categories).and_return([])
      expect(inquiry).to receive(:cancel!)
      subject.perform_available_cancellations!
    end

    it "should not cancel the inquiry, if some inquiry categories remain as in progress" do
      allow(inquiry).to receive(:cancellable?).and_return(false)

      expect(inquiry).not_to receive(:cancel!)

      subject.perform_available_cancellations!
    end

    it "should raise if the inquiry category cannot be found" do
      sample_id = (rand * 100).round
      connect_inquiry_category(inquiry, [])
      cancellation_config[sample_id] = sample_cause

      expect {
        subject.perform_available_cancellations!
      }.to raise_error("InquiryCategory '#{sample_id}' not found!")
    end

    it "should complete an inquiry as well, if needed" do
      cancellation_config[1] = "complete"

      expect(inquiry_category_1).to receive(:complete!).with(no_args)

      subject.perform_available_cancellations!
    end

    context "cancel categories" do
      let(:timeout_feature_switch) { Features::FEATURE_AUTO_CANCEL_INQUIRIES_AFTER_TIMEOUT }

      before do
        allow(Features).to receive(:active?).with(timeout_feature_switch).and_return(true)
      end

      InquiryCategory::CANCEL_EVENTS.each do |cancellation_event|
        it "should cancel the category with the #{cancellation_event}" do
          cancellation_config[1] = cancellation_event.to_s.gsub("cancel_because_", "")

          expect(inquiry_category_1).to receive("#{cancellation_event}!").with(no_args)

          subject.perform_available_cancellations!
        end
      end

      it "should forget the inquiry categories after cancelling them" do
        cancellation_event = InquiryCategory::CANCEL_EVENTS.first
        cancellation_config[1] = cancellation_event.to_s.gsub("cancel_because_", "")
        allow(inquiry_category_1).to receive("#{cancellation_event}!").with(no_args)

        subject.perform_available_cancellations!

        expect(subject.instance_variable_get(:@notification_needed)).to be_empty
      end
    end

    context "inform customer" do
      before do
        allow(inquiry_category_1).to receive(:cancel_because_contract_not_found!)
        allow(inquiry_category_1).to receive(:complete!)
      end

      context "send mail" do
        it "should not send out the mail if no inquiry_categories are cancelled" do
          cancellation_config[1] = "complete"
          configure_category_completed(inquiry_category_1)
          expect(InquiryCategoryMailer)
            .not_to receive(:inquiry_categories_cancelled)
          expect(mail).not_to receive(:deliver_now)
          subject.perform_available_cancellations!
        end

        context "cancelled" do
          before do
            allow(inquiry_category_1).to receive(:cancelled?).and_return(true)
            allow(inquiry_category_2).to receive(:cancelled?).and_return(true)
          end

          it "should send out the mail if one inquiry_category is cancelled" do
            cancellation_config[1] = sample_cause
            expect(InquiryCategoryMailer)
              .to receive(:inquiry_categories_cancelled).with(inquiry_category_1)
            expect(mail).to receive(:deliver_now)
            subject.perform_available_cancellations!
          end

          it "should send out the mail if multiple inquiry_categories are cancelled" do
            allow(inquiry_category_2).to receive(:cancel_because_contract_not_found!)
            cancellation_config[1] = sample_cause
            cancellation_config[2] = sample_cause
            expect(InquiryCategoryMailer)
              .to receive(:inquiry_categories_cancelled).once.with(inquiry_category_1)
            expect(InquiryCategoryMailer)
              .to receive(:inquiry_categories_cancelled).once.with(inquiry_category_2)
            expect(mail).to receive(:deliver_now)
            subject.perform_available_cancellations!
          end

          it "should not send out the mail if cancelled by customer" do
            allow(inquiry_category_1).to receive(:cancel_because_cancelled_by_customer!)
            cancellation_config[1] = "cancelled_by_customer"
            expect(InquiryCategoryMailer).not_to receive(:inquiry_categories_cancelled)
            subject.perform_available_cancellations!
          end
        end
      end

      context "send messenger message" do
        it "should not send out the message if no inquiry_categories are cancelled" do
          cancellation_config[1] = "complete"
          configure_category_completed(inquiry_category_1)
          expect(messenger_class)
            .not_to receive(:inquiry_categories_cancelled)
          expect(mail).not_to receive(:deliver_now)
          subject.perform_available_cancellations!
        end

        context "cancelled" do
          before do
            allow(inquiry_category_1).to receive(:cancelled?).and_return(true)
            allow(inquiry_category_2).to receive(:cancelled?).and_return(true)
          end

          it "should send out the message if one inquiry_category is cancelled" do
            cancellation_config[1] = sample_cause
            expect(messenger_class)
              .to receive(:inquiry_categories_cancelled).with(inquiry_category_1)
            expect(mail).to receive(:deliver_now)
            subject.perform_available_cancellations!
          end

          it "should send out the message if multiple inquiry_categories are cancelled" do
            allow(inquiry_category_2).to receive(:cancel_because_contract_not_found!)
            cancellation_config[1] = sample_cause
            cancellation_config[2] = sample_cause
            expect(messenger_class)
              .to receive(:inquiry_categories_cancelled).once.with(inquiry_category_1)
            expect(messenger_class)
              .to receive(:inquiry_categories_cancelled).once.with(inquiry_category_2)
            expect(mail).to receive(:deliver_now)
            subject.perform_available_cancellations!
          end

          it "should not send out the message if cancelled by customer" do
            allow(inquiry_category_1).to receive(:cancel_because_cancelled_by_customer!)
            cancellation_config[1] = "cancelled_by_customer"
            expect(messenger_class).not_to receive(:inquiry_categories_cancelled)
            subject.perform_available_cancellations!
          end
        end
      end

      context "partner restrictions (e.g. n26)" do
        before do
          allow(inquiry_category_1).to receive(:cancelled?).and_return(true)
          allow(inquiry).to receive(:mandate_acquired_by_partner?).and_return(true)
        end

        it "should not send a mail, if an inquiry category is cancelled" do
          cancellation_config[1] = sample_cause
          expect(InquiryCategoryMailer)
            .not_to receive(:inquiry_categories_cancelled)
          expect(mail).not_to receive(:deliver_now)
          subject.perform_available_cancellations!
        end

        it "should not send a messenger message, if an inquiry category is cancelled" do
          cancellation_config[1] = sample_cause
          expect(messenger_class)
            .not_to receive(:inquiry_categories_cancelled).with(inquiry_category_1)
          subject.perform_available_cancellations!
        end
      end
    end
  end

  context "completion" do
    let(:inquiry_category_1) { mock_inquiry_category(1) }
    let(:inquiry_category_2) { mock_inquiry_category(2) }
    let(:inquiry_categories) { [] }

    before do
      allow(inquiry).to receive(:completable?).and_return(true)
      allow(inquiry).to receive(:complete!)
      allow(inquiry).to receive_message_chain(:inquiry_categories, :in_progress)
        .and_return(inquiry_categories)
    end

    it "should be completed if completable" do
      expect(inquiry).to receive(:complete!).with(no_args)
      subject.perform_completions!
    end

    it "should complete the inquiry categories" do
      inquiry_categories << inquiry_category_1 << inquiry_category_2

      expect(inquiry_category_1).to receive(:complete!).with(no_args)
      expect(inquiry_category_2).to receive(:complete!).with(no_args)

      subject.perform_completions!
    end

    it "should only complete those in progress" do
      expect(inquiry).to receive_message_chain(:inquiry_categories, :in_progress)
        .and_return(inquiry_categories)

      subject.perform_completions!
    end

    it "should fail to complete if the inquiry is not ready for it" do
      allow(inquiry).to receive(:completable?).and_return(false)
      configure_category_completed(inquiry_category_1)

      expect {
        subject.perform_completions!
      }.to raise_error("Inquiry '#{inquiry_id}' is not completable!")
    end
  end

  context "#perform_product_related_completion" do
    let(:inquiry) { create(:inquiry, state: :contacted) }
    let(:inquiry_category) { create(:inquiry_category, inquiry: inquiry) }
    let(:plan) { create(:plan, category: inquiry_category.category) }
    let(:product) { create(:product, inquiry: inquiry, plan: plan) }
    let(:instance) { described_class.new(inquiry) }

    it "raises an error if the product is in an inactive state" do
      product.state = :canceled_by_customer
      expect {
        instance.perform_product_related_completion(product)
      }.to raise_error("Product is not active!")
    end

    it "completes the related inquiry category" do
      instance.perform_product_related_completion(product)
      expect(inquiry_category.reload).to be_completed
    end

    it "completes the inquiry if no more pending inquiry categories there" do
      instance.perform_product_related_completion(product)
      expect(inquiry.reload).to be_completed
    end

    it "does not completes the inquiry if pending inquiry categories exist" do
      second_inquiry_category = create(:inquiry_category)
      inquiry.inquiry_categories << second_inquiry_category
      instance.perform_product_related_completion(product)
      expect(inquiry.reload).not_to be_completed
    end

    it "marks the inquiry as cancelled if one cancelled inquiry categories at least exist" do
      second_inquiry_category = create(:inquiry_category)
      inquiry.inquiry_categories << second_inquiry_category
      second_inquiry_category.update(state: :cancelled)
      instance.perform_product_related_completion(product)
      expect(inquiry.reload).to be_canceled
    end

    it "does not close an inquiry_category if it's already completed" do
      inquiry_category.update(state: :completed)
      instance.perform_product_related_completion(product)
      expect(inquiry.reload).to be_completed
    end
  end
end
