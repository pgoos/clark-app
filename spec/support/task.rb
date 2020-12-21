# frozen_string_literal: true

require "rake"

# Task names should be used in the top-level describe, with an optional
# "rake "-prefix for better documentation. Both of these will work:
#
# 1) describe "foo:bar" do ... end
#
# 2) describe "rake foo:bar" do ... end
#
# Favor including "rake "-prefix as in the 2nd example above as it produces
# doc output that makes it clear a rake task is under test and how it is
# invoked.
module TaskExampleGroup
  extend ActiveSupport::Concern

  included do
    subject(:task) { Rake::Task[task_name] }

    before(:all) do
      load Rails.root.join("app/composites/sales/constituents/opportunity/tasks/update_monthly_admin_performances.rake")
      load Rails.root.join("lib/tasks", "#{task_name.split(":").first}.rake") unless Rake::Task.task_defined?(task_name)
      Rake::Task.define_task(:environment)
    end

    before do
      task.reenable
    end
  end

  def task_name
    self.class.top_level_description.sub(/\Arake /, "")
  end
end

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/spec/tasks/}) do |metadata|
    metadata[:type] = :task
  end

  config.include TaskExampleGroup, type: :task
end
