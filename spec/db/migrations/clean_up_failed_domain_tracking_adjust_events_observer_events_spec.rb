# frozen_string_literal: true

require "rails_helper"
require "migration_data/testing"
require_migration "clean_up_failed_domain_tracking_adjust_events_observer_events"

RSpec.describe CleanUpFailedDomainTrackingAdjustEventsObserverEvents, :integration do
  let(:queue) { "domain_tracking_adjust_events_observer_events" }

  describe "#data" do
    context "job found" do
      before do
        err_mess = <<~ERROR
          Error while trying to deserialize arguments: Couldn't find Inquiry with 'id'=3241359
          /home/deploy/.bundler/optisure_production_app/ruby/2.6.0/gems/activerecord-5.2.4.3/[...]
          many more backtrace lines
        ERROR
        create(:delayed_job, queue: queue, last_error: err_mess)
        create(:delayed_job, queue: "other_queue")
      end

      it "removes the job" do
        expect { described_class.new.data }
          .to change { Delayed::Job.where(queue: queue).count }.by(-1)
      end
    end

    context "no job found" do
      it "raises no error" do
        expect(Delayed::Job.where(queue: queue).count).to eq(0)
        expect { described_class.new.data }.not_to raise_error
      end
    end
  end
end
