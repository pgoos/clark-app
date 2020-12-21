# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
Rails.application.load_tasks

system('source') if Rails.env.production?

# Load the rake tasks inside composites
Rake.add_rakelib("app/composites/payback/tasks")
Rake.add_rakelib("app/composites/n26/constituents/freyr/tasks")
Rake.add_rakelib("app/composites/home24/tasks")
Rake.add_rakelib("app/composites/sales/constituents/opportunity/tasks")
