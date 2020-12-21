# frozen_string_literal: true

require "rails_helper"

RSpec.describe TypeformService::TypeformSync do
  base_directory = "./spec/services/typeform_service/"

  # reference sample comees from: https://admin.typeform.com/form/rNipKZ/create
  tf_reference_string = File.read(base_directory + "tf_fixture_reference_sample.json").freeze
  tf_reference        = JSON.parse(tf_reference_string).freeze
  tf_hidden_question  = JSON.parse(File.read(base_directory + "tf_fixture_question_type_hidden.json")).freeze

  describe "update questionnaire metadata" do
    let!(:questionnaire) {
      build :questionnaire, internal_name: "old_name", description: "old_description", id: "kjQ1zg"
    }

    context "with initial sync" do
      subject { TypeformService::TypeformSync.new(questionnaire) }

      before {
        allow(TypeformService::TypeformApiProxy).to receive(:get_from_typeform_api).and_return(tf_reference)
      }

      it "creates the questions" do
        subject.sync
        expect(questionnaire.questions.size).to eq(8)
      end

      it "updates questionnaire name and description" do
        subject.sync
        expect(questionnaire.internal_name).to eq("Reference Sample currently supported")
        expect(questionnaire.description).to eq("Text for Welcome Screen goes to Questionnaire.description")
      end

      it "persists the updates to the db" do
        subject.sync
        expect { subject.save }.to change { Questionnaire::Question.count }.by(8)
      end
    end


    context "with group question_type" do

      it "moves the group questions into normal order" do
        tf_raw = JSON.parse <<~JSON
          {
            "fields": [
              {
                "id": "1",
                "type": "some"
              },
              {
                "type": "group",
                "properties": {
                  "fields": [
                    {
                      "id": "2"
                    }
                  ]
                }
              },
              {
                "id": "3",
                "type": "some"
              }
            ]
          }
        JSON
        tf = TypeformService::TypeformSync.ungroup(tf_raw)

        expect(tf["fields"].map { |field| field["id"] }).to eq(%w[1 2 3])
      end
    end

    context "when updating previously synced questionnaire" do
      subject { TypeformService::TypeformSync.new(questionnaire) }

      before {
        allow(TypeformService::TypeformApiProxy).to receive(:get_from_typeform_api).and_return(tf_reference)
        subject.sync
      }

      it "applies update to questions" do
        tf_reference_copy = tf_reference.dup
        tf_reference_copy["fields"][1]["properties"]["description"] = "Updated description of short text"
        allow(TypeformService::TypeformApiProxy).to receive(:get_from_typeform_api).and_return(tf_reference_copy)
        subject.sync
        expect(questionnaire.questions[1].description).to eq("Updated description of short text")
      end

      it "ignores unknown new questions" do
        tf_reference_copy = tf_reference.dup
        tf_reference_copy["fields"][1]["id"] = "bogus new id"
        allow(TypeformService::TypeformApiProxy).to receive(:get_from_typeform_api).and_return(tf_reference_copy)
        subject.sync
        expect(questionnaire.questions.size).to eq(8)
        expect(questionnaire.questions[1].question_identifier).not_to eq("bogus new id")
      end
    end

    context "with validation that we support the configured typeform" do
      subject { TypeformService::TypeformSync.new(questionnaire) }

      it "only support questions of certain types" do
        tf_with_hidden = tf_reference.clone
        tf_with_hidden["fields"] << tf_hidden_question
        allow(TypeformService::TypeformApiProxy).to receive(:get_from_typeform_api).and_return(tf_with_hidden)
        expect { subject.sync }.to raise_error(TypeformService::QuestionTypeNotSupported, "hidden")
      end

      # it "does not support jumps at the moment" do
      #   allow(TypeformService::TypeformApiProxy).to receive(:get_from_typeform_api).and_return(tf_basic_jump)
      #   expect { subject.sync }.to raise_error(TypeformService::JumpNotSupported)
      # end
    end
  end
end
