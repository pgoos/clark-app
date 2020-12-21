# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

# Unicorn Killer
if defined?(Unicorn)
  require "unicorn"

  CLARK_ENV_USING_REAL_SERVICES = %w[
    production
    staging
    staging-test-2
    staging-test-3
    staging-test-4
    staging-test-5
    staging-test-6
    staging-test-7
    staging-test-8
    staging-test-9
    staging-test-10
    staging-test-11
    staging-test-12
    staging-test-13
    staging-test-14
    staging-test-15
    staging-test-16
    staging-test-17
    staging-test-18
    staging-test-19
    staging-test-20
  ].freeze

  if CLARK_ENV_USING_REAL_SERVICES.member?(ENV["RAILS_ENV"])
    # Unicorn self-process killer
    require "unicorn/worker_killer"

    # Max requests per worker
    use Unicorn::WorkerKiller::MaxRequests, 1024, 1536

    minimum_memory = ENV.fetch('UNICORN_WORKER_KILLER_MIN', 256)
    maximum_memory = ENV.fetch('UNICORN_WORKER_KILLER_MAX', 420)

    # Max memory size (RSS) per worker
    use Unicorn::WorkerKiller::Oom, (minimum_memory * (1 << 20)), (maximum_memory * (1 << 20))
  end
end

require ::File.expand_path("../config/environment", __FILE__)
run Rails.application
