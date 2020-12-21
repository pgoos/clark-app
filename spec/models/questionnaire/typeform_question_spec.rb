# frozen_string_literal: true
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

RSpec.describe Questionnaire::TypeformQuestion, type: :model do

  # Setup
  # Settings

  it "sets the correct type for the polymorphic field" do
    Questionnaire::TypeformQuestion.create(question_text: "foo", question_type: "text")
    expect(Questionnaire::Question.last.type).to eq("Questionnaire::TypeformQuestion")
  end

  # Constants
  # Attribute Settings
  # Plugins
  # Concerns

  it_behaves_like "an auditable model"

  # State Machine
  # Scopes
  # Associations

  it { expect(subject).to belong_to(:profile_property) }
  it { expect(subject).to have_many(:answers) }
  it { expect(subject).to have_many(:questionings) }
  it { expect(subject).to have_many(:questionnaires).through(:questionings) }

  # Nested Attributes
  # Validations

  it { expect(subject).to validate_presence_of(:question_text) }

  # Callbacks
  # Instance Methods
  # Class Methods

  context "#normalize_identifier(identifier)" do
    {
      "list_abc_choice"    => "list_abc",
      "list_abc"           => "list_abc",
      "list_123_choice"    => "list_123",
      "list_123"           => "list_123",
      "textfield_42435"    => "textfield_42435",
      "number_piwert_iqup" => "number_piwert",
      "number_piwert"      => "number_piwert"
    }.each_pair do |initial, normalized|
      it "should normalize #{initial} to #{normalized}" do
        expect(described_class.normalize_identifier(initial)).to eq(normalized)
      end
    end

    it "should raise an error, if the identifier cannot be normalized" do
      expect {
        described_class.normalize_identifier("wrong")
      }.to raise_error("Cannot normalize identifier 'wrong'!")
    end
  end
end
