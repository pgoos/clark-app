# frozen_string_literal: true

# == Schema Information
#
# Table name: interactions
#
#  id           :integer          not null, primary key
#  type         :string
#  mandate_id   :integer
#  admin_id     :integer
#  topic_id     :integer
#  topic_type   :string
#  direction    :string
#  content      :text
#  metadata     :jsonb
#  acknowledged :boolean
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require "rails_helper"

RSpec.describe Interaction::Sms, type: :model do
  subject { FactoryBot.build(:interaction_sms) }

  it { is_expected.to be_valid }
  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to validate_presence_of(:admin) }
  it { is_expected.to validate_presence_of(:phone_number) }
  it { is_expected.to validate_length_of(:content).is_at_most(640) }

  before do
    Settings.sns.sandbox_disabled = false
  end

  after do
    Settings.reload!
  end

  context "validations" do
    context "plausible numbers" do
      it "does not permit creation with an un processable phone number" do
        subject.phone_number = "911"

        expect(subject).not_to be_valid
        expect(subject.errors.messages[:phone_number]).to be_present
      end

      describe "Internationalized phones" do
        RSpec.shared_examples("internationalized_phones") do
          # For new internationalization add here a NORMALIZED MOBILE number
          existing_internationalizations = {
            "de" => "+491771912227",
            "at" => "+436601234"
          }

          existing_internationalizations.keys.each do |current_i18n|
            context "when context is internationalized as '#{current_i18n}'" do
              before { stub_const("DEFAULT_COUNTRY_CODE", current_i18n) }

              context "when phone is in current country format '#{current_i18n}'" do
                it "is valid" do
                  subject.phone_number = existing_internationalizations[current_i18n]
                  expect(subject).to be_valid
                end
              end

              foreign = existing_internationalizations.keys.delete_if { |c| c == current_i18n }
              foreign.each do |i18n|
                context "when phone is in country format '#{i18n}'" do
                  it "is invalid" do
                    subject.phone_number = existing_internationalizations[i18n]
                    expect(subject).not_to be_valid
                  end
                end
              end
            end
          end
        end

        include_examples "internationalized_phones"
      end
    end

    context "controlling validations" do
      describe "#validates_mobile_phones?" do
        it "should return true by default" do
          expect(subject.validates_mobile_phones?).to be true
        end
      end

      describe "#disable_mobile_validation!" do
        before { subject.disable_mobile_validation! }

        it "predicate method should return false" do
          expect(subject.validates_mobile_phones?).to be false
        end
      end

      describe "#enable_mobile_validation!" do
        before do
          subject.disable_mobile_validation!
          subject.enable_mobile_validation!
        end

        it "predicate method should return true" do
          expect(subject.validates_mobile_phones?).to be true
        end
      end

      context "phone normalization" do
        it "doesn't change an already normalized phone number" do
          subject.phone_number = "+491771912227"

          expect(subject.valid?).to be true
          expect(subject.phone_number).to eq("+491771912227")
        end

        it "adds a + when phone_number does not have it" do
          subject.phone_number = "491771912227"

          expect(subject.valid?).to be true
          expect(subject.phone_number).to eq("+491771912227")
        end

        it "adds a +49 when phone_number does not already have it" do
          subject.phone_number = "1771912227"

          expect(subject.valid?).to be true
          expect(subject.phone_number).to eq("+491771912227")
        end

        it "removes the 0 if a phone starts with +0" do
          subject.phone_number = "+0491771912227"

          expect(subject.valid?).to be true
          expect(subject.phone_number).to eq("+491771912227")
        end

        it "removes the 0 if a phone starts with it and we're validation mobile" do
          subject.enable_mobile_validation!

          subject.phone_number = "0491771912227"

          expect(subject.valid?).to be true
          expect(subject.phone_number).to eq("+491771912227")
        end

        it "it normalizes to digits only" do
          subject.phone_number = "+(49) 177.1^9-122?27"

          expect(subject.valid?).to be true
          expect(subject.phone_number).to eq("+491771912227")
        end

        it "adds +49 to foreign numbers (+55) but then validation won't pass" do
          subject.phone_number = "+551771912228"

          expect(subject.valid?).to be false
          expect(subject.phone_number).to eq("+49551771912228")
        end
      end
    end
  end
end
