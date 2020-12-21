# == Schema Information
#
# Table name: feed_scripts
#
#  id                :integer          not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  script_content    :jsonb
#  is_default_script :boolean
#

require 'rails_helper'

RSpec.describe Feed::Script, type: :model do

  # Setup
  # ---------------------------------------------------------------------------------------

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
  it_behaves_like 'an auditable model'

  # State Machine
  # ---------------------------------------------------------------------------------------

  # Scopes
  # ---------------------------------------------------------------------------------------

  # Associations
  # ---------------------------------------------------------------------------------------

  # Nested Attributes
  # ---------------------------------------------------------------------------------------

  # Validations
  # ---------------------------------------------------------------------------------------

  it { should validate_presence_of(:script_content) }

  it 'should only accept scripts with a unique name' do
    existing = create(:feed_script)
    expect(Feed::Script.new(script_content: existing.script_content)).to_not be_valid
  end

  # Todo: Add tests for custom validator
  #describe 'messages' do
  #  it 'should validate with schema validation' do
  #    blank = FactoryBot.build(:feed_script)
  #    blank.should_not be_valid
  #    blank.errors[:name].should include("can't be blank")

  #    blank.name = "Foo"
  #    blank.should be_valid
  #  end
  #end

  # Callbacks
  # ---------------------------------------------------------------------------------------

  it 'should not be possible to delete the default script 1' do
    default_script_1 = create(:feed_script, name: Feed::Script::NO_SCRIPT_FALLBACK_NAME)
    expect {
      default_script_1.destroy
    }.to raise_error(Feed::Script::ScriptError, "The script '#{Feed::Script::NO_SCRIPT_FALLBACK_NAME}' is the last resort, if no script could be found for the current user state. It may not be deleted!")
  end

  # Instance Methods
  # ---------------------------------------------------------------------------------------

  context 'script visits' do
    before do
      @mandate = create(:mandate)
    end

    it 'should count it\'s visits for a mandate to be zero with no log entries' do
      script_with_1_message = create(:feed_script, name: '1 message', messages: [{}])
      expect(script_with_1_message.times_used(@mandate)).to be(0)
    end

    it 'should count it\'s visits for a mandate' do
      script_with_1_message = create(:feed_script, name: '1 message', messages: [{}])
      create(:feed_log, script_id: script_with_1_message.id, mandate_id: @mandate.id)
      expect(script_with_1_message.times_used(@mandate)).to be(1)
    end

    it 'should ignore visits of other mandates' do
      mandate_2 = create(:mandate)
      script_with_1_message = create(:feed_script, name: '1 message', messages: [{}])
      create(:feed_log, script_id: script_with_1_message.id, mandate_id: mandate_2.id)
      expect(script_with_1_message.times_used(@mandate)).to be(0)
    end

    it 'should respect the count of messages to calculate script visits' do
      script_with_2_messages = create(:feed_script, name: '1 message', messages: [{}, {}])
      create(:feed_log, script_id: script_with_2_messages.id, mandate_id: @mandate.id)
      create(:feed_log, script_id: script_with_2_messages.id, mandate_id: @mandate.id)
      expect(script_with_2_messages.times_used(@mandate)).to be(1)
    end

    it 'should only count script calls of the given script' do
      dummy_script = create(:feed_script, name: 'dummy script', messages: [{}])
      script_with_1_message = create(:feed_script, name: '1 message', messages: [{}])
      create(:feed_log, script_id: dummy_script.id, mandate_id: @mandate.id)
      create(:feed_log, script_id: script_with_1_message.id, mandate_id: @mandate.id)
      expect(script_with_1_message.times_used(@mandate)).to be(1)
    end
  end

  context 'script active flag' do
    before do
      @feed_script = create(:feed_script)
      @feed_script.deactivate!
    end

    it 'should default to inactive' do
      feed_script = Feed::Script.new
      expect(feed_script.active?).to be(false)
      expect(feed_script.script_content['active']).to be(false)
    end

    it 'should be active, if the flag in the code is set to true' do
      @feed_script.script_content['active'] = true
      expect(@feed_script.active?).to be(true)
    end

    it 'should be possible to activate it through a method' do
      @feed_script.activate!
      expect(@feed_script.active?).to be(true)
      expect(@feed_script.script_content['active']).to be(true)
    end

    it 'should be possible to deactivate it through a method' do
      @feed_script.activate!
      @feed_script.deactivate!
      expect(@feed_script.active?).to be(false)
      expect(@feed_script.script_content['active']).to be(false)
    end

    it 'should persist a call of activate! immediately' do
      @feed_script.activate!
      expect(Feed::Script.find(@feed_script.id).active?).to be(true)
    end

    it 'should persist a call of deactivate! immediately' do
      @feed_script.activate!
      @feed_script.deactivate!
      expect(Feed::Script.find(@feed_script.id).active?).to be(false)
    end
  end

  # Class Methods
  # ---------------------------------------------------------------------------------------

  context 'upload/download' do
    it 'should render all scripts as an array' do
      script = create(:feed_script)
      all = Feed::Script.serialize_all
      parsed = JSON.parse(all)
      expect(parsed).to be_a_kind_of(Array)
      expect(parsed[0]).to eq(script.script_content)
    end

    it 'should import a JSON array of scripts' do
      script_array = [sample_script('script 1'), sample_script('script 2')]
      script_json = script_array.to_json

      Feed::Script.import_all(script_json)

      expect(Feed::Script.by_name('script 1')).to_not be_empty
      expect(Feed::Script.by_name('script 2')).to_not be_empty
    end

    it 'should modify an existing script and not just create a new one' do
      script = create(:feed_script)
      script.listens_on << 'some-other-event'
      expected_events = script.listens_on
      script_json = [script.script_content].to_json

      Feed::Script.import_all(script_json)

      scripts_from_db = Feed::Script.by_name(script.name)
      expect(scripts_from_db.size).to eq(1)
      expect(scripts_from_db.first.listens_on).to match_array(expected_events)
    end

    it 'should delete a script, if the imported file did not contain it' do
      script_array = [sample_script('script 1'), sample_script('script 2')]
      script_json = script_array.to_json

      Feed::Script.import_all(script_json)

      script_array = [sample_script('script 2')]
      script_json = script_array.to_json

      Feed::Script.import_all(script_json)

      expect(Feed::Script.by_name('script 1')).to be_empty
      expect(Feed::Script.all.size).to eq(1)
    end
  end

  it 'should be a default script, if listens_on is empty' do
    script = sample_script('Default Script')
    script['listens_on'] = []

    saved_script = Feed::Script.create!(script_content: script)
    expect(saved_script.is_default_script).to be(true)
  end

  it 'should not be a default script, if listens_on is filled' do
    script = sample_script('Default Script')
    script['listens_on'] = ['some-event']

    saved_script = Feed::Script.create!(script_content: script)
    expect(saved_script.is_default_script).to be(false)
  end

  it 'should query fall back scripts' do
    script = sample_script('Default Script')
    script['listens_on'] = []

    saved_script = Feed::Script.create!(script_content: script)
    expect(Feed::Script.fall_back_scripts.first.name).to eq(saved_script.name)
  end

  context 'last resort' do
    it 'should know, if it is the last resort script' do
      last_resort = create(:feed_script, name: Feed::Script::NO_SCRIPT_FALLBACK_NAME, listens_on: [])
      expect(last_resort.is_last_resort?).to be(true)
    end

    it 'should know, if a default script is not the last resort script' do
      other_script = create(:feed_script, name: 'default not being last resort', listens_on: [])
      expect(other_script.is_last_resort?).to be(false)
    end

    it 'should know, that a regular script is not the last resort script' do
      other_script = create(:feed_script, name: 'not default', listens_on: ['some-event'])
      expect(other_script.is_last_resort?).to be(false)
    end
  end

  def sample_script(name)
    {
        "listens_on" => ["testscript"],
        "name" => "#{name}",
        "messages" => []
    }
  end
end
