# == Schema Information
#
# Table name: feed_logs
#
#  id          :integer          not null, primary key
#  mandate_id  :integer
#  script_id   :integer
#  from_server :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  text        :text
#  message_id  :string
#  event       :string
#

require 'rails_helper'

RSpec.describe Feed::Log, type: :model do

  # Setup
  # ---------------------------------------------------------------------------------------
  let(:mandate) { create(:mandate) }

  # Settings
  # ---------------------------------------------------------------------------------------

  # Constants
  # ---------------------------------------------------------------------------------------

  # Attribute Settings
  # ---------------------------------------------------------------------------------------

  # Plugins
  # ---------------------------------------------------------------------------------------

  # Concerns
  # ---------------------------------------------------------------------------------------

  # State Machine
  # ---------------------------------------------------------------------------------------

  # Scopes
  # ---------------------------------------------------------------------------------------
  context 'log entries with events' do
    it 'should just return log entries with events' do
      # user = create(:user, mandate: mandate)
      create(:feed_log, mandate: mandate, from_server: true, message_id: nil, text: nil, event: 'some-event')
      create(:feed_log, mandate: mandate, from_server: true, message_id: nil, text: nil, event: 'some-event')
      create(:feed_log, mandate: mandate, from_server: true, message_id: 1, text: 'some text', event: nil)
      expect(Feed::Log.where_with_event(mandate).size).to be(2)
      Feed::Log.where_with_event(mandate).each do |entry|
        expect(entry.event).to_not be(nil)
      end
    end
  end

  context 'message entries' do
    let(:regular_script) {
      create(:feed_script, name: 'sample regular script', listens_on: ['sample-event'])
    }

    it 'should not include technical log entries' do
      create(:feed_log, mandate_id: mandate.id, script_id: 0)
      entries = Feed::Log.where_with_script_message(mandate)
      expect(entries.empty?).to be(true)
    end

    it 'should include log entries coming from a script' do
      create(:feed_log, mandate_id: mandate.id, script_id: regular_script.id)
      entries = Feed::Log.where_with_script_message(mandate)
      expect(entries.last.script_id).to eq(regular_script.id)
    end

    it 'should use entries of the appropriate mandate instance' do
      other_mandate = create(:mandate)
      create(:feed_log, mandate_id: other_mandate.id, script_id: regular_script.id)
      entries = Feed::Log.where_with_script_message(mandate)
      expect(entries.empty?).to be(true)
    end
  end

  include_examples 'between_scopeable', :created_at

  # Associations
  # ---------------------------------------------------------------------------------------

  # Nested Attributes
  # ---------------------------------------------------------------------------------------

  # Validations
  # ---------------------------------------------------------------------------------------
  it { should validate_presence_of(:mandate_id) }

  it 'should validate the presence of a message_id and text, if no event is given' do
    expect(build(:feed_log, from_server: true, message_id: 1, text: nil, event: nil)).to_not be_valid
    expect(build(:feed_log, from_server: true, message_id: nil, text: 'some text', event: nil)).to_not be_valid
    expect(build(:feed_log, from_server: true, message_id: 1, text: 'some text', event: nil)).to be_valid
  end

  it 'should validate the presence of an event, if text and message_id are missing' do
    expect(build(:feed_log, from_server: true, message_id: nil, text: nil, event: nil)).to_not be_valid
    expect(build(:feed_log, from_server: true, message_id: nil, text: nil, event: 'some-event')).to be_valid
  end

  # Callbacks
  # ---------------------------------------------------------------------------------------

  # Instance Methods
  # ---------------------------------------------------------------------------------------

  # Class Methods
  # ---------------------------------------------------------------------------------------
end
