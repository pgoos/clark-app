# == Schema Information
#
# Table name: questionnaire_questionings
#
#  id                        :integer          not null, primary key
#  questionnaire_id          :integer
#  questionnaire_question_id :integer
#  sort_index                :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#

require 'rails_helper'

RSpec.describe Questionnaire::Questioning, type: :model do

  #
  # Setup
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Constants
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Attribute Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Plugins
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Concerns
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #
  it_behaves_like 'an auditable model'

  #
  # State Machine
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Scopes
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Associations
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  it { expect(subject).to belong_to(:question) }
  it { expect(subject).to belong_to(:questionnaire) }

  #
  # Nested Attributes
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Validations
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  context 'set sort_index on create' do
    let(:questionnaire) { create(:questionnaire) }

    it 'calls the set_sort_index method on create' do
      expect(subject).to receive(:set_sort_index)
      subject.run_callbacks(:create)
    end

    it 'sets the sort_index to the next number if no order is given' do
      expect(Questionnaire::Questioning.create(questionnaire: questionnaire, question: nil).sort_index).to eq(1)
      expect(Questionnaire::Questioning.create(questionnaire: questionnaire, question: nil).sort_index).to eq(2)
    end

    it 'uses the provided sort_index when one is provided' do
      expect(Questionnaire::Questioning.create(questionnaire: questionnaire, question: nil, sort_index: 42).sort_index).to eq(42)
    end
  end

  #
  # Callbacks
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Instance Methods
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #


  #
  # Class Methods
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

end

