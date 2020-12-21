# frozen_string_literal: true
# == Schema Information
#
# Table name: inquiries
#
#  id            :integer          not null, primary key
#  state         :string
#  created_at    :datetime
#  updated_at    :datetime
#  mandate_id    :integer
#  company_id    :integer
#  remind_at     :date
#  contacted_at  :datetime
#  subcompany_id :integer
#  gevo          :integer          default(0), not null
#


require "rails_helper"

RSpec.describe Inquiry, type: :model do
  # Setup

  subject { build_stubbed(:inquiry) }

  it { is_expected.to be_valid }

  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns

  it_behaves_like "a commentable model"
  it_behaves_like "an auditable model"
  it_behaves_like "a documentable"

  # Index
  # State Machine

  describe "state machine" do
    context "with initial state" do
      let(:inquiry) { create(:inquiry) }

      it "is in_creation" do
        expect(inquiry.state).to eq("in_creation")
      end

      it "transitions to pending" do
        expect(inquiry.accept).to eq(true)
        expect(inquiry.state).to eq("pending")
      end

      it "transitions to canceled" do
        expect(inquiry.cancel).to eq(true)
        expect(inquiry.state).to eq("canceled")
      end

      it "does not transition to other states" do
        expect(inquiry.contact).to eq(false)
        expect(inquiry.complete).to eq(false)
      end
    end

    context "with accepted mandate" do
      let(:mandate) { create(:mandate, state: "accepted") }

      it "initial state is accepted" do
        inquiry = build(:inquiry)
        mandate.inquiries << inquiry
        inquiry.save

        expect(mandate.state).to eq("accepted")
      end

      it "transitions inquiry to complete" do
        inquiry = build(:inquiry, :in_creation, mandate: mandate)
        expect(inquiry.complete).to eq(true)
      end
    end

    context "with state: pending" do
      let(:inquiry) { create(:inquiry, state: "pending") }

      it "is pending" do
        expect(inquiry.state).to eq("pending")
      end

      it "transitions to contacted" do
        expect(inquiry.contact).to eq(true)
        expect(inquiry.state).to eq("contacted")
      end

      it "transitions to canceled" do
        expect(inquiry.cancel).to eq(true)
        expect(inquiry.state).to eq("canceled")
      end

      it "transitions to complete" do
        expect(inquiry.complete).to eq(true)
        expect(inquiry.state).to eq("completed")
      end

      it "does not transition to other states" do
        expect(inquiry.accept).to eq(false)
      end
    end

    context "with state: contacted" do
      let(:inquiry) { create(:inquiry, state: "contacted") }

      it "is contacted" do
        expect(inquiry.state).to eq("contacted")
      end

      it "transitions to completed" do
        expect(inquiry.complete).to eq(true)
        expect(inquiry.state).to eq("completed")
      end

      it "transitions to canceled" do
        expect(inquiry.cancel).to eq(true)
        expect(inquiry.state).to eq("canceled")
      end

      it "does not transition to other states" do
        expect(inquiry.accept).to eq(false)
        expect(inquiry.contact).to eq(false)
      end
    end

    context "with state: completed" do
      let(:inquiry) { create(:inquiry, state: "completed") }

      it "is completed" do
        expect(inquiry.state).to eq("completed")
      end

      it "does not transition to other states" do
        expect(inquiry.contact).to eq(false)
        expect(inquiry.accept).to eq(false)
        expect(inquiry.complete).to eq(false)
        expect(inquiry.cancel).to eq(false)
      end
    end
  end

  context "when contacted" do
    let(:mandate) { create(:mandate) }
    let(:company) { create(:gkv_company) }
    let(:inquiry) do
      create(:inquiry, mandate: mandate, company: company, state: "pending")
    end
    let(:default_admin) { create(:admin) }
    let(:admin) { create(:admin) }

    it "sets the contacted_at date" do
      Timecop.freeze do
        expect {
          inquiry.contact
        }.to change { inquiry.contacted_at }.from(nil).to(DateTime.current)
      end
    end
  end

  context "delete follow ups" do
    let!(:mandate) { create(:mandate) }
    let!(:company) { create(:gkv_company) }
    let!(:inquiry) { create(:inquiry, mandate: mandate, company: company, state: "contacted") }

    before do
      # To make sure that we don't accidentally delete too much (since using unscoped)
      mandate.follow_ups.create(due_date: 1.week.from_now)
      inquiry.follow_ups.create(due_date: 2.weeks.from_now)
    end

    it "deletes inquiries when an inquiry is completed" do
      expect {
        inquiry.complete
      }.to change { FollowUp.count }.by(-1)
    end

    it "deletes inquiries when an inquiry is canceled" do
      expect {
        inquiry.cancel
      }.to change { FollowUp.count }.by(-1)
    end
  end

  # Scopes
  context "email insurer blacklist" do
    let(:non_blacklisted_company) { create(:company) }
    let(:blacklisted_company) { create(:company, inquiry_blacklisted: true) }

    let!(:inquiry_whitelisted) { create(:inquiry, company: non_blacklisted_company) }
    let!(:inquiry_blacklisted) { create(:inquiry, company: blacklisted_company) }

    it { expect(Inquiry.all).to include(inquiry_whitelisted) }
    it { expect(Inquiry.all).to include(inquiry_blacklisted) }
    it { expect(Inquiry.insurer_whitelisted).to include(inquiry_whitelisted) }
    it { expect(Inquiry.insurer_whitelisted).not_to include(inquiry_blacklisted) }
  end

  # Associations

  %i[mandate company].each do |model|
    it { expect(subject).to belong_to(model) }
  end

  it { expect(subject).to have_many(:products) }
  it { expect(subject).to have_many(:follow_ups).dependent(:destroy) }
  it { expect(subject).to have_many(:interactions) }
  it { expect(subject).to have_many(:inquiry_categories).dependent(:destroy) }
  it { expect(subject).to have_many(:categories).through(:inquiry_categories) }

  describe "An inquiry" do
    let(:inquiry) { create(:inquiry) }

    it "is not destroyed if it is associated with products" do
      create(:product, inquiry: inquiry)
      inquiry.destroy
      expect(inquiry.errors[:base].count).to eq(1)
      expect(Inquiry.find_by(id: inquiry.id)).to eq(inquiry)
    end

    it "is destroyed if is not associated with products" do
      inquiry.destroy
      expect(Inquiry.find_by(id: inquiry.id)).to be_nil
    end
  end

  describe "active_categories" do
    let(:cancelled_category) { create(:category) }
    let(:non_cancelled_category) { create(:category) }
    let(:inquiry) do
      create(:inquiry, inquiry_categories: [
               create(:inquiry_category, :cancelled_by_customer, category: cancelled_category),
               create(:inquiry_category, :in_progress, category: non_cancelled_category)
             ])
    end

    it "does not return cancelled categories" do
      expect(inquiry.categories.size).to eq 2
      expect(inquiry.active_categories.size).to eq 1
      expect(inquiry.active_categories.first).to eq non_cancelled_category
    end
  end

  # Nested Attributes ------------------------------------------------------------------------------
  it { expect(subject).to accept_nested_attributes_for(:inquiry_categories) }

  # Validations ------------------------------------------------------------------------------------
  %i[mandate company].each do |attr|
    it { is_expected.to validate_presence_of(attr) }
  end


  # Delegates --------------------------------------------------------------------------------------
  it { is_expected.to delegate_method(:owner_ident).to(:mandate) }
  it { is_expected.to delegate_method(:accessible_by).to(:mandate) }
  it { is_expected.to delegate_method(:accessible_by?).to(:mandate) }
  it { is_expected.to delegate_method(:mandate_accepted?).to(:mandate).as(:accepted?) }

  it do
    is_expected.to delegate_method(:mandate_acquired_by_partner?)
      .to(:mandate).as(:acquired_by_partner?)
  end
  it { is_expected.to delegate_method(:company_ident).to(:company).as(:ident) }
  it { is_expected.to delegate_method(:company_name).to(:company).as(:name) }
  it { is_expected.to delegate_method(:subcompany_ident).to(:subcompany).as(:ident) }

  # Callbacks
  describe "accept_inquiry" do
    it "accepts the inquiries automatically if mandate is accepted" do
      accepted_mandate = create(:mandate, state: :accepted)
      auto_accepted_inquiry = create(:inquiry, mandate: accepted_mandate)
      expect(auto_accepted_inquiry).to be_pending
    end

    it "does not accept the inquiries automatically if mandate is not accepted" do
      created_mandate = create(:mandate, state: :created)
      inquiry = create(:inquiry, mandate: created_mandate)
      expect(inquiry).to be_in_creation
    end
  end

  # Instance Methods

  describe "#uploaded_documents_count" do
    it "returns a valid count" do
      expect(subject.uploaded_documents_count).to eq(0)
    end
  end

  context "#gkv?" do
    let(:company) { FactoryBot.build_stubbed(:gkv_company) }
    let(:inquiry) { FactoryBot.build_stubbed(:inquiry, company: company, state: "pending") }

    it "is true for gkv companies" do
      expect(inquiry).to be_gkv
    end

    it "is false for other companies" do
      expect(subject).not_to be_gkv
    end

    it "broadcasts the gkv_inquiry_created event" do
      expect { inquiry.run_callbacks(:create) }.to broadcast(:gkv_inquiry_created, inquiry)
    end

    it "does not broadcasts the gkv_inquiry_created event for non gkv inquiries" do
      expect { subject.run_callbacks(:create) }.not_to broadcast(:gkv_inquiry_created)
    end

    context "subcompany" do
      let(:subcompany_gkv) { FactoryBot.build_stubbed(:subcompany_gkv) }
      let(:inquiry) { FactoryBot.build_stubbed(:inquiry, subcompany: subcompany_gkv)}

      it "is true for a gkv subcompany" do
        expect(inquiry).to be_gkv
      end
    end
  end

  context "#cancellable?" do
    let(:category_in_progress) { FactoryBot.build_stubbed(:inquiry_category, state: "in_progress")}
    let(:category_completed) { FactoryBot.build_stubbed(:inquiry_category, state: "completed")}
    let(:category_cancelled) { FactoryBot.build_stubbed(:inquiry_category, state: "cancelled")}

    it "should be cancellable if there are no categories and it was not cancelled" do
      expect(subject).to be_cancellable
    end

    it "should not be cancellable if completed" do
      expect(FactoryBot.build_stubbed(:inquiry, :completed)).not_to be_cancellable
    end

    it "should not be cancellable if cancelled" do
      expect(FactoryBot.build_stubbed(:inquiry, :cancelled)).not_to be_cancellable
    end

    it "should not be cancellable if there's an inquiry category in progress" do
      inquiry = FactoryBot.build_stubbed(:inquiry, inquiry_categories: [category_in_progress])
      expect(inquiry).not_to be_cancellable
    end

    it "should not be cancellable if there's only a completed inquiry category" do
      inquiry = FactoryBot.build_stubbed(:inquiry, inquiry_categories: [category_completed])
      expect(inquiry).not_to be_cancellable
    end

    it "should be cancellable if there's only a cancelled inquiry category" do
      inquiry = FactoryBot.build_stubbed(:inquiry, inquiry_categories: [category_cancelled])
      expect(inquiry).to be_cancellable
    end

    it "should be not be cancellable if there are some in progress" do
      inquiry_categories = [category_cancelled, category_in_progress, category_completed]
      inquiry = FactoryBot.build_stubbed(:inquiry, inquiry_categories: inquiry_categories)
      expect(inquiry).not_to be_cancellable
    end
  end

  context "#completable?" do
    let(:category_in_progress) { FactoryBot.build_stubbed(:inquiry_category, state: "in_progress")}
    let(:category_completed) { FactoryBot.build_stubbed(:inquiry_category, state: "completed")}
    let(:category_cancelled) { FactoryBot.build_stubbed(:inquiry_category, state: "cancelled")}

    it "should not be completable if there are no categories and it was not cancelled" do
      expect(subject).not_to be_completable
    end

    it "should not be completable if completed" do
      expect(FactoryBot.build_stubbed(:inquiry, :completed)).not_to be_completable
    end

    it "should not be completable if cancelled" do
      expect(FactoryBot.build_stubbed(:inquiry, :cancelled)).not_to be_completable
    end

    it "should be completable if there's an inquiry category in progress" do
      inquiry = FactoryBot.build_stubbed(:inquiry, inquiry_categories: [category_in_progress])
      expect(inquiry).to be_completable
    end

    it "should be completable if there's only a completed inquiry category" do
      inquiry = FactoryBot.build_stubbed(:inquiry, inquiry_categories: [category_completed])
      expect(inquiry).to be_completable
    end

    it "should not be completable if there's only a cancelled inquiry category" do
      inquiry = FactoryBot.build_stubbed(:inquiry, inquiry_categories: [category_cancelled])
      expect(inquiry).not_to be_completable
    end

    it "should be not be completable if there are some cancelled" do
      inquiry_categories = [category_in_progress, category_cancelled, category_completed]
      inquiry = FactoryBot.build_stubbed(:inquiry, inquiry_categories: inquiry_categories)
      expect(inquiry).not_to be_completable
    end
  end

  describe "#send_adjust_ptp_inquiry_created_48h_event" do
    it "send tracking event to adjust" do
      expect { create(:inquiry) }.to broadcast(:send_adjust_ptp_inquiry_created_48h)
    end
  end

  describe "#send_inquiry_cancelled_event" do
    let(:inquiry) { create(:inquiry) }
    let(:listener) { double("Domain::Inquiries::InquiryObserver") }

    it "broadcasts the cancellation event" do
      inquiry.subscribe(listener)

      expect(listener).to receive(:send_inquiry_cancelled).with(inquiry)
      expect { inquiry.cancel! }.to broadcast(:send_inquiry_cancelled, inquiry)
    end
  end

  # Class Methods
  # Protected
  # Private
end
