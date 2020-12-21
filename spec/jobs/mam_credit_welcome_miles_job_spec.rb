# frozen_string_literal: true

require "rails_helper"

RSpec.describe MamCreditWelcomeMilesJob, type: :job do
  let(:positive_integer) { (100 * rand).round + 1 }
  let(:mandate) { instance_double(Mandate, id: positive_integer) }
  let(:booking_class) { Domain::Partners::MilesMoreWelcomeBooking }
  let(:booking) { instance_double(booking_class) }
  let(:mam_lifter_class) { Domain::Partners::MilesMore }
  let(:mam_lifter) { instance_double(Domain::Partners::MilesMore) }

  before do
    allow(Mandate).to receive(:find).and_return(nil)
    allow(Mandate).to receive(:find).with(positive_integer).and_return(mandate)
    allow(booking_class).to receive(:new).with(mandate).and_return(booking)
    allow(mam_lifter_class).to receive(:new).with(mandate).and_return(mam_lifter)
    allow(booking).to receive(:requires_remote_booking?).and_return(true)
  end

  it { is_expected.to be_a(ClarkJob) }

  it "should append to the queue 'mandate_accepted_tasks'" do
    expect(subject.queue_name).to eq("mandate_accepted_tasks")
  end

  it "should execute the booking" do
    expect(mam_lifter).to receive(:credit_miles_single_booking).with(booking)
    subject.perform(mandate_id: positive_integer)
  end

  it "should do nothing, if the mandate is gone" do
    expect(booking_class).not_to receive(:new)
    subject.perform(mandate_id: positive_integer + 1)
  end

  it "should not do anything, if there's no remote booking required" do
    allow(booking).to receive(:requires_remote_booking?).and_return(false)
    expect(mam_lifter).not_to receive(:credit_miles_single_booking)
    subject.perform(mandate_id: positive_integer)
  end
end
