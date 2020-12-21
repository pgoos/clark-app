# frozen_string_literal: true

RSpec.configure do |config|
  config.include ActiveJob::TestHelper

  config.before do
    if ActiveJob::Base.queue_adapter.class == ActiveJob::QueueAdapters::TestAdapter
      clear_enqueued_jobs
      clear_performed_jobs
    end
  end
end

class ActiveJob::QueueAdapters::DelayedJobAdapter
  class EnqueuedJobs
    def clear
      Delayed::Job.destroy_all
    end
  end

  class PerformedJobs
    def clear
      Delayed::Job.destroy_all
    end
  end

  def enqueued_jobs
    EnqueuedJobs.new
  end

  def performed_jobs
    PerformedJobs.new
  end
end
