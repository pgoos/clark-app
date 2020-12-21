# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Questionnaires::Question do
  let(:model) { build_stubbed(:questionnaire_question, metadata: metadata) }
  let(:metadata) { {} }

  it "should init as QuestionMultipleRadio, if the question type is multiple-choice with multiple == false" do
    metadata["multiple-choice"] = {"multiple" => false}
    model.question_type = "multiple-choice"
    expect(described_class.init(model: model)).to be_a(Domain::Questionnaires::QuestionMultipleRadio)
  end

  it "should init as QuestionMultipleCheckbox, if the question type is multiple-choice with multiple == true" do
    metadata["multiple-choice"] = {"multiple" => true}
    model.question_type = "multiple-choice"
    expect(described_class.init(model: model)).to be_a(Domain::Questionnaires::QuestionMultipleCheckbox)
  end

  it "should init as QuestionText, if the question type is text with multiline == false" do
    metadata["text"] = {"multiline" => false}
    model.question_type = "text"
    expect(described_class.init(model: model)).to be_a(Domain::Questionnaires::QuestionText)
  end

  it "should init as QuestionTextArea, if the question type is text with multiline == true" do
    metadata["text"] = {"multiline" => true}
    model.question_type = "text"
    expect(described_class.init(model: model)).to be_a(Domain::Questionnaires::QuestionTextArea)
  end

  it "should init as QuestionDate, if the question type is date" do
    model.question_type = "date"
    expect(described_class.init(model: model)).to be_a(Domain::Questionnaires::QuestionDate)
  end
end
