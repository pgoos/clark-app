# == Schema Information
#
# Table name: questionnaire_questions
#
#  id                  :integer          not null, primary key
#  type                :string
#  profile_property_id :integer
#  question_text       :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  value_type          :string
#  question_identifier :string
#  description         :text
#  required            :boolean
#  question_type       :string
#  metadata            :jsonb
#

require "rails_helper"

RSpec.describe Questionnaire::Question, type: :model do
  it_behaves_like "an auditable model"

  it { expect(subject).to belong_to(:profile_property) }
  it { expect(subject).to have_many(:answers) }
  it { expect(subject).to have_many(:questionings) }
  it { expect(subject).to have_many(:questionnaires).through(:questionings) }

  it "should build an identifier before creation" do
    subject.question_text = "Sample question?"
    subject.question_type = Questionnaire::TypeformQuestion.name
    subject.run_callbacks(:create)
    expect(subject.question_identifier).not_to be_blank
  end
end


