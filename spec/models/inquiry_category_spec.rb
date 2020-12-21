# frozen_string_literal: true

# == Schema Information
#
# Table name: inquiry_categories
#
#  id                           :integer          not null, primary key
#  inquiry_id                   :integer
#  category_id                  :integer
#  product_number               :string
#  created_at                   :datetime
#  updated_at                   :datetime
#  deleted_by_customer          :boolean          default(FALSE), not null
#  customer_documents_dismissed :boolean          default(FALSE)
#  cancellation_cause           :integer          default("no_cancellation_cause")
#  state                        :string           default("in_progress")
#

require "rails_helper"

RSpec.describe InquiryCategory, type: :model do
  subject { FactoryBot.build(:inquiry_category) }

  context "callbacks" do
    let(:inquiry_category) { create(:inquiry_category) }

    it { expect(inquiry_category).to callback(:publish_created_event).after(:create) }
    it { expect(inquiry_category).to callback(:publish_updated_event_for_data_fields).after(:update) }
    it { expect(inquiry_category).to callback(:publish_deleted_event).after(:destroy) }
    it { expect(inquiry_category).to callback(:send_inquiry_category_created_event).after(:create) }
    it { expect(inquiry_category).to callback(:send_inquiry_category_deleted_event).after(:destroy) }

    describe "#send_inquiry_category_created_event" do
      let(:listener) { double("Domain::InquiryCategories::InquiryCategoryCreated") }

      context "with created state" do
        it "broadcasts the creation event" do
          subject.subscribe(listener)
          expect(listener).to receive(:send_inquiry_category_created).with(subject)
          expect { subject.save! }.to broadcast(:send_inquiry_category_created, subject)
        end
      end
    end

    describe "#send_inquiry_category_deleted_event" do
      let(:listener) { double("Domain::InquiryCategories::InquiryCategoryDeleted") }

      it "broadcasts the creation event" do
        inquiry_category.subscribe(listener)
        expect(listener).to receive(:send_inquiry_category_deleted).with(inquiry_category.id)
        expect { inquiry_category.destroy! }.to broadcast(:send_inquiry_category_deleted, inquiry_category.id)
      end
    end

    describe "#send_cancelled_inquiry_category_event" do
      let(:listener) { double("Domain::InquiryCategories::InquiryCategoryCancelled") }

      context "with cancelled state" do
        it "broadcasts the cancellation event" do
          inquiry_category = build :inquiry_category, :in_progress
          inquiry_category.subscribe(listener)
          expect(listener).to receive(:send_cancelled_inquiry_category).with(inquiry_category)
          expect { inquiry_category.cancel_because_contract_not_found }.to broadcast(:send_cancelled_inquiry_category,
                                                                                     inquiry_category)
        end
      end
    end
  end

  it { is_expected.to be_valid }
  it { is_expected.to delegate_method(:owner_ident).to(:inquiry) }
  it { is_expected.to delegate_method(:accessible_by).to(:inquiry) }
  it { is_expected.to delegate_method(:accessible_by?).to(:inquiry) }
  it { is_expected.to delegate_method(:mandate).to(:inquiry) }
  it { is_expected.to delegate_method(:mandate_accepted?).to(:inquiry) }
  it { is_expected.to delegate_method(:company_name).to(:inquiry) }
  it { is_expected.to delegate_method(:mandate_acquired_by_partner?).to(:inquiry) }
  it { is_expected.to delegate_method(:category_ident).to(:category).as(:ident) }
  it { is_expected.to delegate_method(:name).to(:category) }
  it { is_expected.to delegate_method(:vertical_ident).to(:category) }

  it { is_expected.to be_no_cancellation_cause }

  # FIXME: This can go away once we upgrade to shoulda-matcher v4+
  context "delegate methods when category is nil" do
    subject { described_class.new(category_id: nil) }

    it { expect(subject.name).to be nil }
    it { expect { subject.name }.not_to raise_error }
    it { expect(subject.vertical_ident).to be nil }
    it { expect { subject.vertical_ident }.not_to raise_error }
  end

  it_behaves_like "event_publishable"

  context "when a related product exists" do
    it "should be false, if no product exists" do
      expect(subject).not_to be_product
    end

    it "should be true, if a product exists and it is not sold by clark" do
      plan = create(:plan, category: subject.category)
      create(:product, plan: plan, mandate: subject.mandate)
      expect(subject).to be_product
    end

    it "should be true, if a product of a related combo category exists" do
      combo = create(:combo_category, included_category_ids: [subject.category.id])
      plan = create(:plan, category: combo)
      create(:product, plan: plan, mandate: subject.mandate)
      expect(subject).to be_product
    end
  end

  context "state machine" do
    it "is in_progress initially" do
      expect(subject).to be_in_progress
    end

    context "-> :completed" do
      let(:listener) { double("Domain::InquiryCategories::InquiryCategoryCompleted") }

      before do
        subject.save!
        subject.complete
      end

      it "can complete from in_progress" do
        expect(subject).to be_completed
      end

      it "infers to the cancellation reason 'no_cancellation_cause' if completed" do
        expect(subject).to be_no_cancellation_cause
      end

      described_class::CANCEL_EVENTS.each do |cancellation_event|
        it "cannot be cancelled from complete for the reason #{cancellation_event}" do
          expect(subject.send(cancellation_event)).to be_falsey
        end
      end
    end

    describe "#send_inquiry_category_completed" do
      let(:listener) { double("Domain::InquiryCategories::InquiryCategoryCompleted") }

      context "-> :completed" do
        it "broadcasts the completion event" do
          subject.subscribe(listener)
          expect(listener).to receive(:send_inquiry_category_completed).with(subject)
          expect { subject.complete }.to broadcast(:send_inquiry_category_completed, subject)
        end
      end
    end

    context "-> :cancelled" do
      context "cancelled already" do
        before do
          subject.state = "cancelled"
          subject.save!
        end

        it "can be cancelled from in_progress" do
          expect(subject).to be_cancelled
        end

        it "cannot complete from cancelled" do
          expect(subject.complete).to be_falsey
        end
      end

      described_class::CANCEL_EVENTS.each do |cancellation_event|
        it "infers the cancellation reason from the according event '#{cancellation_event}'" do
          subject.save!
          subject.send(cancellation_event)
          as_enum_vaue = cancellation_event.to_s.gsub("cancel_because_", "")
          expect(subject.send("#{as_enum_vaue}?")).to be_truthy
        end
      end

      context "#cancel_because_cancelled_by_customer" do
        before do
          subject.save!
        end

        it "should also update the according flag" do
          subject.cancel_because_cancelled_by_customer!
          expect(subject.deleted_by_customer).to eq(true)
        end

        described_class::CANCEL_EVENTS.except(:cancel_because_cancelled_by_customer).each do |event|
          it "should leave the flag for different causes like #{event}" do
            subject.send("#{event}!")
            expect(subject.deleted_by_customer).to be_falsey
          end
        end
      end
    end
  end

  describe "validations" do
    let(:inquiry) { create(:inquiry) }
    let(:category1) { create(:category) }
    let(:category2) { create(:category) }
    let(:inquiry_category) do
      create(:inquiry_category, inquiry: inquiry, category: category1)
    end

    context "uniqueness of category" do
      it "should not be valid if there is already that category for a given inquiry" do
        attributes = inquiry_category.attributes.except("id").compact
        duplicate = InquiryCategory.new(attributes)
        expect(duplicate).not_to be_valid
      end

      it "should be valid if the category is unique for a given inquiry" do
        not_a_duplicate = FactoryBot.build(:inquiry_category, inquiry: inquiry, category: category2)
        expect(not_a_duplicate).to be_valid
      end

      it "should be valid if the categories are same, but for different inquiries" do
        inquiry_category
        second = create(:inquiry, mandate: inquiry.mandate)
        not_a_duplicate = FactoryBot.build(:inquiry_category, inquiry: second, category: category1)
        expect(not_a_duplicate).to be_valid
      end

      context "handle existing duplicates properly" do
        let(:unvalidated_inquiry_category) do
          Class.new(ApplicationRecord) do
            self.table_name = "inquiry_categories"

            belongs_to :inquiry
          end
        end

        it "should allow to change an existing duplicate" do
          attributes = FactoryBot.build(:inquiry_category, inquiry: inquiry).attributes.compact
          duplicate1 = unvalidated_inquiry_category.create!(attributes)
          duplicate2 = unvalidated_inquiry_category.create!(attributes)
          [duplicate1.id, duplicate2.id].each do |duplicate_id|
            expect(InquiryCategory.find(duplicate_id)).to be_valid
          end
        end
      end
    end
  end
end
