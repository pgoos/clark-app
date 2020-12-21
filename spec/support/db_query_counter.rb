# frozen_string_literal: true

class DbQueryCounter
  cattr_accessor :query_count do
    Thread.current["query_count"] ||= 0
  end

  cattr_accessor :query_counter_file do
    Thread.current["query_count_file"]
  end

  IGNORED_SQL = [
    /^PRAGMA (?!(table_info))/,
    /^BEGIN$/,
    /^COMMIT$/,
    /^ROLLBACK$/
  ].freeze

  def call(_name, _start, _finish, _message_id, values)
    self.class.query_count += 1 unless IGNORED_SQL.any? { |r| values[:sql] =~ r }
  end

  class << self
    def reset
      self.query_count = 0
    end

    def init(marker: "")
      dir = Rails.root.join("results")
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      f_path = dir.join("db_query_count_#{marker}#{SecureRandom.hex[0..5]}.csv")

      # cleanup
      query_counter_file.close if query_counter_file.is_a?(File) && !query_counter_file.closed?
      FileUtils.rm(f_path) if File.exist?(f_path)

      # open
      self.query_counter_file = File.open(f_path, "a:utf-8")
      query_counter_file.puts "count, example"
    end

    def close
      query_counter_file.close
      self.query_counter_file = nil
    end

    def log(description)
      return if query_count.zero?
      query_counter_file.puts("#{DbQueryCounter.query_count}, #{description}")
    end
  end
end

RSpec.configure do |config|
  next if ENV["COUNT_DB_QUERIES"].blank?

  config.before(:suite) do
    DbQueryCounter.init(marker: config.inclusion_filter[:integration].present? ? "integration" : "")
    ActiveSupport::Notifications.subscribe("sql.active_record", DbQueryCounter.new)
  end

  config.after(:suite) do
    DbQueryCounter.close
  end

  config.append_before do
    DbQueryCounter.reset
  end

  config.append_after do |x|
    query_count = DbQueryCounter.query_count
    DbQueryCounter.log(x.location)
    expect(query_count).to be <= ENV["DB_QUERIES_LIMIT"].to_i if ENV["DB_QUERIES_LIMIT"].present?
  end
end
