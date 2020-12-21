# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Ratings::RequestRatingAfterSale do
  subject(:start) { described_class }

  let(:user) { create(:user, :with_mandate) }
  let(:admin) { create(:admin) }
  let(:opportunity) { create :opportunity, state: "offer_phase", mandate: user.mandate }

  context "#successfully_sold", :integration do
    before { Timecop.freeze(Time.zone.parse("2018-09-01 17:00")) }

    after { Timecop.return }

    it "enqueues mail on the delayed job to be sent later" do
      # since rating email is DISABLED due to
      # https://clarkteam.atlassian.net/browse/JCLARK-43675
      # expected_mail_delivery_time = Time.zone.tomorrow.beginning_of_day + 11.hours
      # subject.successfully_sold(opportunity)
      # job_time = Time.zone.at(enqueued_jobs.last[:at])
      # expect {
      #   MandateMailer.rate_clark.deliver_later
      # }.to have_enqueued_job.on_queue("mailers")
      # expect(job_time).to eq(expected_mail_delivery_time)
    end
  end
end
