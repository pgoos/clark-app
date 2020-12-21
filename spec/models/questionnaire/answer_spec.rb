# frozen_string_literal: true

# == Schema Information
#
# Table name: questionnaire_answers
#
#  id                        :integer          not null, primary key
#  questionnaire_question_id :integer
#  question_text             :string
#  answer                    :jsonb
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  questionnaire_response_id :integer
#

require "rails_helper"

RSpec.describe Questionnaire::Answer, type: :model do
  it_behaves_like "an auditable model"

  it { expect(subject).to belong_to(:questionnaire_response) }
  it { expect(subject).to belong_to(:question) }


  it { expect(subject).to validate_presence_of(:answer) }
  it { expect(subject).to validate_presence_of(:question_text) }
  it { expect(subject).to validate_presence_of(:question) }
  it { expect(subject).to validate_presence_of(:questionnaire_response) }

  it { is_expected.to delegate_method(:question_identifier).to(:question) }
  it { is_expected.to delegate_method(:question_type).to(:question) }
end

