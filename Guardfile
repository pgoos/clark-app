# frozen_string_literal: true

require "guard/rspec/dsl"
system "./bin/dev/docker_volume_paths"

# A sample Guardfile
# More info at https://github.com/guard/guard#readme

## Uncomment and set this to only include directories you want to watch
# directories %w(app lib config test spec features)

## Uncomment to clear the screen before every task
# clearing :on

## Guard internally checks for changes in the Guardfile and exits.
## If you want Guard to automatically start up again, run guard in a
## shell loop, e.g.:
##
##  $ while bundle exec guard; do echo "Restarting Guard..."; done
##
## Note: if you are using the `directories` clause above and you are not
## watching the project directory ('.'), then you will want to move
## the Guardfile to a watched dir and symlink it back, e.g.
#
#  $ mkdir config
#  $ mv Guardfile config/
#  $ ln -s config/Guardfile .
#
# and, you'll have to watch "config/Guardfile" instead of "Guardfile"

# Watch only specific directories
dirs = %w(
  app
  lib
  spec
  client/app
  app/assets
  db/cms_fixtures
  db/cms_fixtures
  tmp/clark/letter_opener
)
directories(dirs)

# Enable notifications on Mac OS X 10.8, or higher
notification :terminal_notifier if `uname` =~ /Darwin/

# for live reload during frontend development
guard :livereload do
  watch(%r{client/app/.+\.(js|ts|hbs)$})

  # Rails Assets Pipeline
  watch(%r{(app|vendor)(/assets/\w+/(.+\.(css|html|png|jpg|svg))).*}) { |m| "/assets/#{m[3]}" }

  # CMS fixtures
  watch(%r{db/cms_fixtures/.+\.(yml|html|js|css|png|jpg|svg)$})
  watch(%r{app/assets/stylesheets/.+\.(scss)$})

  # enable style injection for scss
  watch(%r{(app|vendor)(/assets/\w+/(.+)\.(scss))}) { |m| "/assets/#{m[3]}.css" }
  watch(%r{client/app/(.+)\.(scss)$}) { |m| "/de/app/assets/client.css" }
end

def define_rspec_watchers
  dsl = Guard::RSpec::Dsl.new(self)

  # Rspec files
  rspec = dsl.rspec
  watch(rspec.spec_helper)  { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)

  # Ruby files
  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files) { |m| "#{rspec.spec_dir}/lib/#{m[1]}_spec.rb" }

  # Rails files
  rails = dsl.rails
  dsl.watch_spec_files_for(rails.app_files)

  watch(rails.controllers) do |m|
    [
      "#{rspec.spec_dir}/features/#{m[1]}",
      "#{rspec.spec_dir}/controllers/#{m[1]}_controller",
    ]
  end

  watch("app/services/robo_advisor.rb") { "#{rspec.spec_dir}/services/robo_advisor" }
  watch(rails.app_controller) { "#{rspec.spec_dir}/controllers" }
end

def define_robo_watchers
  dsl = Guard::RSpec::Dsl.new(self)
  rspec = dsl.rspec
  rails = dsl.rails

  watch(rspec.spec_helper) { rspec.spec_dir }

  watch("app/services/robo_advisor.rb") { "#{rspec.spec_dir}/services/robo_advisor/" }
  watch(rails.app_controller) { "#{rspec.spec_dir}/controllers" }
end

group :unit_frontend do
  $stderr.puts ":unit_frontend not configured yet"
end

def rspec_cmd(tags=[])
  default_tags = ["~clark_with_master_data"]
  tags_option = (tags + default_tags).map { |t| "--tag #{t}"}.join(" ")
  "bundle exec spring rspec #{tags_option}"
end

group :no_browser do
  guard :rspec, cmd: rspec_cmd(["~browser"]) do
    define_rspec_watchers
  end
end

group :no_browser_profile do
  guard :rspec, cmd: rspec_cmd(["~browser"]) + " --profile" do
    define_rspec_watchers
  end
end

group :not_slow do
  guard :rspec, cmd: rspec_cmd(["~slow"]) do
    define_rspec_watchers
  end
end

group :not_slow_profile do
  guard :rspec, cmd: rspec_cmd(["~slow"]) + " --profile" do
    define_rspec_watchers
  end
end

group :all_tests do
  guard :rspec, cmd: rspec_cmd do
    define_rspec_watchers
  end
end

group :all_tests_profile do
  guard :rspec, cmd: rspec_cmd + " --profile" do
    define_rspec_watchers
  end
end

group :focus do
  guard :rspec, cmd: rspec_cmd(["focus"]) do
    define_rspec_watchers
  end
end

group :robo do
  guard :rspec, cmd: rspec_cmd do
    define_robo_watchers
  end
end

scope group: :no_browser

guard :shell do
  letter_opener_tmp_dirs.each do |label_tmp_dir|
    watch(%r{#{label_tmp_dir}/.+\.(html)$}) do |modified_files|
      `open #{modified_files[0]}`
    end
  end
end
