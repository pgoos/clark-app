# frozen_string_literal: true

# Contains a step for triggering rake tasks

When(/rake task "([^"]*:[^"]*)" is being executed/) do |task_name|
  ApiFacade.new.automation_helpers.execute_task(task_name)
end
