# frozen_string_literal: true
# == Schema Information
#
# Table name: appointments
#
#  id                :integer          not null, primary key
#  state             :string
#  starts            :datetime
#  ends              :datetime
#  call_type         :string
#  appointable_id    :integer
#  appointable_type  :string
#  mandate_id        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  method_of_contact :string           default("phone")
#

require "rails_helper"

RSpec.describe Appointment, type: :model do
  # Setup

  subject { FactoryBot.build_stubbed(:appointment) }

  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  it_behaves_like "an auditable model"
  it_behaves_like "a documentable"

  # State Machine
  describe "appointment states" do
    subject { create(:appointment) }

    it_behaves_like "an auditable model"

    it "has requested as initial state" do
      expect(subject).to be_requested
    end

    it "can be accepted" do
      expect(subject.accept).to eq(true)
      expect(subject).to be_accepted
    end

    it "can be cancelled" do
      expect(subject.cancel).to eq(true)
      expect(subject).to be_cancelled
    end

    it "can be cancelled, although it had been accepted" do
      subject.update_attributes(state: "accepted")
      expect(subject.cancel).to eq(true)
      expect(subject).to be_cancelled
    end

    context "admin unnasigned" do
      subject { create(:appointment, :requested, appointable: create(:opportunity, :unassigned)) }

      it "cannot be accepted" do
        expect(subject.accept).to be_falsey
        expect(subject.errors[:admin]).not_to be_empty
      end
    end
  end

  # Scopes
  # Associations

  it { expect(subject).to belong_to(:mandate) }

  # Nested Attributes
  # Validations

  it { is_expected.to validate_presence_of(:starts) }
  it { is_expected.to validate_presence_of(:call_type) }
  it { is_expected.to validate_presence_of(:mandate) }
  it { is_expected.to validate_presence_of(:appointable) }

  context "validates optionally" do
    before do
      subject.validate_timeframe = true
    end

    it "if the appointment is the same day, do not allow it" do
      Timecop.freeze(2016, 10, 18, 10) do
        subject.starts = Time.zone.tomorrow.beginning_of_day - 1.minute
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:starts]).to include(I18n.t("activerecord.errors.models.appointment.starts.too_early"))
      end
    end

    it "if the appointment is not same day, allow it" do
      Timecop.freeze(2016, 10, 18, 10) do
        subject.starts = Time.zone.tomorrow.beginning_of_day + 1.minute
        expect(subject).to be_valid
      end
    end

    it "if the appointment starts at most 10 d from now" do
      Timecop.freeze(2016, 10, 18, 10) do
        subject.starts = Time.zone.today.advance(days: 11).beginning_of_day
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:starts]).to include(I18n.t("activerecord.errors.models.appointment.starts.too_late"))
      end
    end

    context "when there is the same appointment" do
      let(:prev_appointment) { create(:appointment) }
      let(:params) do
        {
          mandate: prev_appointment.mandate,
          appointable: prev_appointment.appointable
        }
      end

      def build_from_appointment(appointment, diff_starts=nil, diff_ends=nil)
        timeslot = {
          starts: (diff_starts.nil? ? nil : appointment.starts + diff_starts),
          ends:   (diff_ends.nil?   ? nil : appointment.ends + diff_ends)
        }

        build(:appointment, params.merge(timeslot))
      end

      context "when #ends exists" do
        context "when the state is :canceled" do
          let(:prev_appointment) { create(:appointment, state: :cancelled) }

          it "is valid" do
            Timecop.freeze do
              appointment = build(
                :appointment,
                params.merge(starts: prev_appointment.starts + 1.minute, ends: prev_appointment.ends + 1.minute)
              )
              expect(appointment).to be_valid
            end
          end
        end

        context "when the state is not :canceled" do
          it "don't allow if starts between prev starts and ends" do
            Timecop.freeze do
              appointment = build_from_appointment(prev_appointment, 1.minute, 1.minute)
              expect(appointment).not_to be_valid
              expect(appointment.errors.messages[:starts])
                .to include(I18n.t("activerecord.errors.models.appointment.starts.intersect"))
            end
          end

          it "don't allow if ends between prev starts and ends" do
            Timecop.freeze do
              appointment = build_from_appointment(prev_appointment, -1.minute, -1.minute)
              expect(appointment).not_to be_valid
              expect(appointment.errors.messages[:starts])
                .to include(I18n.t("activerecord.errors.models.appointment.starts.intersect"))
            end
          end

          it "don't allow if within prev starts and ends" do
            Timecop.freeze do
              appointment = build_from_appointment(prev_appointment, 1.minute, -1.minute)
              expect(appointment).not_to be_valid
              expect(appointment.errors.messages[:starts])
                .to include(I18n.t("activerecord.errors.models.appointment.starts.intersect"))
            end
          end

          it "don't allow if contains prev starts and ends" do
            Timecop.freeze do
              appointment = build_from_appointment(prev_appointment, -1.minute, 1.minute)
              expect(appointment).not_to be_valid
              expect(appointment.errors.messages[:starts])
                .to include(I18n.t("activerecord.errors.models.appointment.starts.intersect"))
            end
          end

          it "allows if out of prev starts and ends" do
            Timecop.freeze do
              appointment = build(
                :appointment,
                params.merge(starts: prev_appointment.ends + 1.minute, ends: prev_appointment.ends + 61.minutes)
              )
              expect(appointment).to be_valid
            end
          end
        end
      end

      context "when #ends doesn't exist" do
        context "when the state is :canceled" do
          let(:prev_appointment) { create(:appointment, state: :cancelled) }

          it "is valid" do
            Timecop.freeze do
              appointment = build_from_appointment(prev_appointment, 0.minutes)
              expect(appointment).to be_valid
            end
          end
        end

        context "when the state is not :canceled" do
          it "don't allow if starts equals to prev starts" do
            appointment = build_from_appointment(prev_appointment, 0.minutes)
            expect(appointment).not_to be_valid
            expect(appointment.errors.messages[:starts])
              .to include(I18n.t("activerecord.errors.models.appointment.starts.intersect"))
          end

          it "allows if starts doesn't equals to prev starts" do
            appointment = build_from_appointment(prev_appointment, 1.minute)
            expect(appointment).to be_valid
          end
        end
      end
    end
  end

  # Callbacks
  # Instance Methods

  it { is_expected.to delegate_method(:admin_first_name).to(:appointable) }
  it { is_expected.to delegate_method(:category_ident).to(:appointable) }

  context ":call_type" do
    before do
      subject.call_type = nil
      expect(subject.call_type).to be_nil
    end

    it "allows the right value type for phone" do
      subject.call_type = ValueTypes::CallTypes::PHONE
      expect(subject.call_type).to eq(ValueTypes::CallTypes::PHONE)
    end

    it "allows the right value type for video" do
      subject.call_type = ValueTypes::CallTypes::VIDEO
      expect(subject.call_type).to eq(ValueTypes::CallTypes::VIDEO)
    end
  end

  describe "#call_type=", :integration do
    subject! { create(:appointment) }

    let(:phone_call_type) { ValueTypes::CallTypes.with_name("PHONE") }
    let(:hash_type) { { "value" => "PHONE", "type" => "CallTypes" } }
    let(:string_type) { "PHONE" }

    it "set call_type from the ValueTypes::CallTypes object" do
      subject.call_type= phone_call_type

      expect(subject.call_type).to eq(phone_call_type)
    end

    it "set call_type from the hash type object" do
      subject.call_type= hash_type

      expect(subject.call_type).to eq(phone_call_type)
    end

    it "set call_type from the string object" do
      subject.call_type= string_type

      expect(subject.call_type).to eq(phone_call_type)
    end

    it "rase ArgumentError" do
      expect { subject.call_type= "skype_call" }.to raise_error(ArgumentError, "'skype_call' is not a valid call_type")
    end
  end

  # Class Methods
end
