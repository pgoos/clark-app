# == Schema Information
#
# Table name: interactions
#
#  id           :integer          not null, primary key
#  type         :string
#  mandate_id   :integer
#  admin_id     :integer
#  topic_id     :integer
#  topic_type   :string
#  direction    :string
#  content      :text
#  metadata     :jsonb
#  acknowledged :boolean
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'rails_helper'

RSpec.describe Interaction::Message, type: :model do

  let(:message) { FactoryBot.build :interaction_message }

  describe "#set_default_values" do
    subject { message.send(:set_default_values) }

    context 'when acknowledged is nil' do
      before { message.acknowledged = nil }

      it 'sets acknowledged to false' do
        expect{ subject }.to change{ message.acknowledged }.from(nil).to(false)
      end
    end

    context 'when acknowledged is false' do
      before { message.acknowledged = false }

      it 'does not change acknowledged value' do
        expect{ subject }.not_to change{ message.acknowledged }
      end
    end

    context 'when acknowledged is true' do
      before { message.acknowledged = true }

      it 'does not change acknowledged value' do
        expect{ subject }.not_to change{ message.acknowledged }
      end
    end
  end
end
