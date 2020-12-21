# frozen_string_literal: true

require "rails_helper"
require "composites/customer/constituents/surveys/jobs/close_nps_cycle_job"

RSpec.describe Customer::Constituents::Surveys::Jobs::CloseNPSCycleJob do
  let(:nps_cycle) { create(:nps_cycle, :closing, maximum_score: 10) }

  it "is an ApplicationJob" do
    expect(described_class).to be < ApplicationJob
  end

  it "should append 'close_nps_cycle' to the queue" do
    expect(subject.queue_name).to eq("close_nps_cycle")
  end

  it "enqueues the job on the 'close_nps_cycle' queue" do
    expect { described_class.perform_later(nps_cycle.id) }.to have_enqueued_job.on_queue("close_nps_cycle")
  end

  it "calls CloseNPSCycle interactor to initiate customers export " do
    expect(Customer::Constituents::Surveys::Interactors::CloseNPSCycle).to receive_message_chain(:new, :call)
    described_class.perform_now(nps_cycle.id)
  end
end
