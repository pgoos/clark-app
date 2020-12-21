# frozen_string_literal: true

require "rails_helper"

RSpec.describe TypeformService::TypeformJumpMapper do
  base_directory = "./spec/services/typeform_service/"
  tf_basic_jump = JSON.parse(File.read(base_directory + "tf_fixture_basic_jump.json")).freeze

  context "when querying fields" do
    subject {
      TypeformService::TypeformJumpMapper.new(tf_basic_jump)
    }

    let(:question_with_choice_jump) { build(:questionnaire_question, question_identifier: "c7KBTPpLEVYo", metadata: {}) }
    let(:question_no_jump) { build(:questionnaire_question, question_identifier: "RTMdQ12quHfp", metadata: {}) }
    let(:question_always_jump) { build(:questionnaire_question, question_identifier: "XthZszVGrLjR", metadata: {}) }
    let(:question_with_yesno_jump) { build(:questionnaire_question, question_identifier: "jIATt23C9qCL", metadata: {}) }
    let!(:questionnaire) {
      build :questionnaire,
            internal_name: "old_name", description: "old_description", id: "kjQ1zg",
            questions: [question_with_choice_jump, question_no_jump, question_always_jump]
    }


    it "extracts the right jumps" do
      expect(subject.jump_actions_for_field(question_with_choice_jump.question_identifier).size).to eq(2)
      expect(subject.jump_actions_for_field(question_no_jump.question_identifier).size).to eq(0)
    end

    it "removes previous jumps" do
      question_no_jump.metadata = {jumps: ["remove me"]}
      subject.configure_jumps(question_no_jump)
      expect(question_no_jump.metadata["jumps"]).to eq([])
    end

    it "creates choice jumps" do
      subject.configure_jumps(question_with_choice_jump)
      expect(question_with_choice_jump.metadata["jumps"].size).to eq(2)
      expect(question_with_choice_jump.metadata["jumps"][0]["destination"]["id"]).to eq("RTMdQ12quHfp")
      expect(question_with_choice_jump.metadata["jumps"][0]["conditions"][0]["field"]).to eq("c7KBTPpLEVYo")
      expect(question_with_choice_jump.metadata["jumps"][0]["conditions"][0]["value"]).to eq("Jump to #3")
    end

    it "creates choice yes/no" do
      subject.configure_jumps(question_with_yesno_jump)
      expect(question_with_yesno_jump.metadata["jumps"].size).to eq(2)
      expect(question_with_yesno_jump.metadata["jumps"][0]["destination"]["id"]).to eq("j8CglIFJETbc")
      expect(question_with_yesno_jump.metadata["jumps"][0]["conditions"][0]["field"]).to eq("jIATt23C9qCL")
      expect(question_with_yesno_jump.metadata["jumps"][0]["conditions"][0]["value"]).to eq("1")
      expect(question_with_yesno_jump.metadata["jumps"][1]["destination"]["id"]).to eq("cA9DNyYGUQU4")
      expect(question_with_yesno_jump.metadata["jumps"][1]["conditions"][0]["field"]).to eq("jIATt23C9qCL")
      expect(question_with_yesno_jump.metadata["jumps"][1]["conditions"][0]["value"]).to eq("0")
    end

    it "creates always true jump" do
      subject.configure_jumps(question_always_jump)
      expect(question_always_jump.metadata["jumps"].size).to eq(1)
      expect(question_always_jump.metadata["jumps"][0]["destination"]["id"]).to eq("jIATt23C9qCL")
      expect(question_always_jump.metadata["jumps"][0]["conditions"]).to eq("true")
    end

  end
end
