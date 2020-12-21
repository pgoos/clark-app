# frozen_string_literal: true

RSpec.configure do |config|
  def set_to_truncation(config)
    keep_tables = Settings.keep_tables_cms + Settings.keep_tables_fixtures
    if config.inclusion_filter[:with_master_data]
      keep_tables += Settings.keep_tables_master_data
    end

    DatabaseCleaner.strategy =
      :truncation,
      {except: keep_tables}
  end

  config.before(:suite) do
    # Clean up everything except for the cms pages before the test suite runs
    keep_tables = Settings.keep_tables_cms

    if config.inclusion_filter[:with_master_data]
      keep_tables += Settings.keep_tables_master_data
    end
    DatabaseCleaner.clean_with(:truncation, except: keep_tables)

    # Load the fixtures (document types, permissions and roles)
    fixtures_dir   = Rails.root.join("spec", "fixtures")
    fixtures_files = Dir.glob(fixtures_dir.join("**", "*.yml"))
                        .reject { |f| f.include?("data_import") || f.include?("vcr_cassettes") }
                        .map    { |f| File.basename(f, ".yml") }

    ActiveRecord::FixtureSet.create_fixtures(fixtures_dir, fixtures_files)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, truncation: true) do
    set_to_truncation config
  end

  config.before(:each, js: true) do
    set_to_truncation config
  end

  config.before(:each) do
    Domain::MasterData::Utils::Cache.invalidate_all
    DatabaseCleaner.start
  end

  config.append_after(:each) do |x|
    begin
      DatabaseCleaner.clean
    rescue => e
      Rails.logger.error "Exception during cleanup: #{e} caused by #{e.cause}"
      Rails.logger.error "retrying in 2s"
      # Recover from thread locks and retry the database clean after a slight delay
      sleep 2
      DatabaseCleaner.clean
    end

    Remember.file_path = x.file_path
  end

  config.after(:context) do
    keep_tables     = Settings.keep_tables_cms + Settings.keep_tables_fixtures
    if config.inclusion_filter[:with_master_data]
      keep_tables += Settings.keep_tables_master_data
    end

    should_truncate = %r{\./spec/api/clark_api}.match(Remember.file_path).present?
    DatabaseCleaner.clean_with(:truncation, except: keep_tables) if should_truncate
    Remember.file_path = nil
  end
end
