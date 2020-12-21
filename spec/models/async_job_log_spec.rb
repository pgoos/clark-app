# frozen_string_literal: true
# == Schema Information
#
# Table name: async_job_logs
#
#  id         :integer          not null, primary key
#  topic_id   :integer
#  topic_type :string
#  severity   :string           not null
#  message    :jsonb            not null
#  job_id     :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  job_name   :string
#  queue_name :string
#


require "rails_helper"

RSpec.describe AsyncJobLog, type: :model do
  # Setup
  # Settings
  # Constants
  # Attribute Settings

  # PLEASE NOTE: The shoulda matcher for enums does ot apply here, since it needs an integer column.
  context "enum severity" do
    it { expect(described_class.severities).to eq(
      "debug" => "DEBUG", "info" => "INFO", "warn" => "WARN", "error" => "ERROR", "fatal" => "FATAL"
    ) }

    it { expect(described_class.new(severity: :debug)).to be_debug }
    it { expect(described_class.new(severity: :debug)).not_to be_bad }
    it { expect(described_class.new(severity: "debug")).not_to be_bad }
    it { expect(described_class.new(severity: :info)).to be_info }
    it { expect(described_class.new(severity: :info)).not_to be_bad }

    it { expect(described_class.new(severity: :warn)).to be_warn }
    it { expect(described_class.new(severity: :warn)).to be_bad }
    it { expect(described_class.new(severity: :error)).to be_error }
    it { expect(described_class.new(severity: :error)).to be_bad }
    it { expect(described_class.new(severity: :fatal)).to be_fatal }
    it { expect(described_class.new(severity: :fatal)).to be_bad }
  end


  # Plugins
  # Concerns
  # State Machine
  # Scopes
  # Associations

  it { expect(subject).to belong_to(:topic) }

  # Nested Attributes
  # Validations

  it { expect(subject).to validate_presence_of(:job_id) }
  it { expect(subject).to validate_presence_of(:severity) }
  it { expect(subject).to validate_presence_of(:message) }

  # Callbacks
  # Instance Methods
  # Class Methods
end

