# frozen_string_literal: true

require "rails_helper"

RSpec.describe TypeformService::TypeformWebMapper do
  context "when Question Mapping" do
    it "with generic properties" do
      generic_question = JSON.parse <<~JSON
        {
            "id": "y4Es7BS2rHhR",
            "title": "Yes \/ No question text, not required",
            "ref": "03250c2b-936b-47c1-ac21-b23ec10f6731",
            "properties": {
                "description": "Some generic question description"
            },
            "validations": {
                "required": true
            },
            "type": "yes_no"
        }
      JSON

      q = Questionnaire::Question.new
      TypeformService::TypeformWebMapper.map_generic(generic_question, q)
      expect(q.required).to be(true)
      expect(q.question_text).to eq("Yes \/ No question text, not required")
      expect(q.value_type).to eq('Text')
      expect(q.description).to eq("Some generic question description")
    end

    it "with yes_no" do
      yes_no = JSON.parse <<~JSON
        {
          "id": "y4Es7BS2rHhR",
          "title": "Yes \/ No question text, not required",
          "ref": "03250c2b-936b-47c1-ac21-b23ec10f6731",
          "properties": {
            "description": "Description of Yes \/ No question"
          },
          "validations": {
            "required": false
          },
          "type": "yes_no"
        }
      JSON

      q = Questionnaire::Question.new(metadata: {})
      TypeformService::TypeformWebMapper.map_question(yes_no, q)
      expect(q.metadata["multiple-choice"]["choices"].length).to be(2)
      expect(q.metadata["multiple-choice"]["multiple"]).to be(false)

      # checking first and last
      expect(q.metadata["multiple-choice"]["choices"][0]["label"]).to eq("Ja")
      expect(q.metadata["multiple-choice"]["choices"][0]["value"]).to eq("1")
      expect(q.metadata["multiple-choice"]["choices"][0]["position"]).to eq(0)

      expect(q.metadata["multiple-choice"]["choices"][1]["label"]).to eq("Nein")
      expect(q.metadata["multiple-choice"]["choices"][1]["value"]).to eq("0")
      expect(q.metadata["multiple-choice"]["choices"][1]["position"]).to eq(1)
      expect(q.required).to be(false)
      expect(q.description).to eq("Description of Yes / No question")
    end

    it "with list properties" do
      list_field = JSON.parse <<~JSON
        {
          "id": "ovxHpmNc5csr",
          "title": "Multiple Choice question text, required, multi selection",
          "ref": "3ad13c4b-3972-4fb7-b63c-ac6e01881f28",
          "properties": {
            "description": "Description of multiple choice question",
            "randomize": false,
            "allow_multiple_selection": true,
            "allow_other_choice": false,
            "vertical_alignment": true,
            "choices": [
              {
                "id": "rcMthEjlL3YA",
                "ref": "cd7fd484-7210-454b-a2f1-80f658c53525",
                "label": "Choice one text"
              },
              {
                "id": "GLYlecupf4zv",
                "ref": "f7565d01-9b92-4824-88d4-e298213e43fe",
                "label": "Choice two text"
              },
              {
                "id": "chxUbLNpvjP4",
                "ref": "b7f45daa-bcca-4450-b1d5-90e61303f7d6",
                "label": "Choice three text"
              }
            ]
          },
          "validations": {
            "required": true
          },
          "type": "multiple_choice"
        }
      JSON

      q = Questionnaire::Question.new(metadata: {})
      TypeformService::TypeformWebMapper.map_question(list_field, q)
      expect(q.metadata["multiple-choice"]["choices"].length).to be(3)
      expect(q.metadata["multiple-choice"]["multiple"]).to be(true)

      # checking first and last
      expect(q.metadata["multiple-choice"]["choices"][0]["label"]).to eq("Choice one text")
      expect(q.metadata["multiple-choice"]["choices"][0]["value"]).to eq("Choice one text")
      expect(q.metadata["multiple-choice"]["choices"][0]["position"]).to eq(0)

      expect(q.metadata["multiple-choice"]["choices"][2]["label"]).to eq("Choice three text")
      expect(q.metadata["multiple-choice"]["choices"][2]["value"]).to eq("Choice three text")
      expect(q.metadata["multiple-choice"]["choices"][2]["position"]).to eq(2)
      expect(q.required).to be(true)
      expect(q.description).to eq("Description of multiple choice question")
    end

    it "with text field" do
      text_field = JSON.parse <<~JSON
        {
          "id": 14691603,
          "question": "Bitte erl\u00e4utere die Rechtsschutzsch\u00e4den.",
          "attachment": "",
          "required": false,
          "type": "textfield",
          "position": 9,
          "label": "Bitte erl\u00e4utere die Rechtsschutzsch\u00e4den.",
          "calculations": []
        }
      JSON

      q = Questionnaire::Question.new(metadata: {})
      TypeformService::TypeformWebMapper.map_question(text_field, q)
      expect(q.metadata["text"]["multiline"]).to eq(false)
      expect(q.metadata["multiple-choice"]).to be(nil)
    end

    it "with text area" do
      text_area = JSON.parse <<~JSON
        {
          "id": "htNj8QiKas8W",
          "title": "Hast du noch weitere Informationen oder Anmerkungen für uns?",
          "ref": "0fbc7acc-eeae-4a55-bd56-62539999b80b",
          "properties": {
            "description": "Hier ist Platz für Punkte, die Du uns noch mitgeben möchtest oder Fragen, die Du an uns hast."
          },
          "validations": {
            "required": false
          },
          "type": "long_text"
        }
      JSON

      q = Questionnaire::Question.new(metadata: {})
      TypeformService::TypeformWebMapper.map_question(text_area, q)
      expect(q.metadata["text"]["multiline"]).to eq(true)
      expect(q.metadata["multiple-choice"]).to be(nil)
    end

    it "with number field" do
      number_field = JSON.parse <<~JSON
        {
           "id": 14689262,
           "question": "Wie gross ist die Wohsdsdf?",
           "position": 3,
            "type": "number",
            "required": false,
            "attachment": "",
            "calculations": [],
            "label": "Wie gross sfafsdf?"
          }
      JSON

      q = Questionnaire::Question.new(metadata: {})
      TypeformService::TypeformWebMapper.map_question(number_field, q)
      expect(q.metadata["text"]["multiline"]).to eq(false)
      expect(q.metadata["multiple-choice"]).to be(nil)
    end

    it "with date question" do
      date = JSON.parse <<~JSON
        {
          "id": 14691603,
          "question": "when were you born?",
          "attachment": "",
          "required": false,
          "type": "date",
          "position": 9,
          "label": "Bitte erl\u00e4utere die Rechtsschutzsch\u00e4den.",
          "calculations": []
        }
      JSON

      q = Questionnaire::Question.new(metadata: {})
      TypeformService::TypeformWebMapper.map_question(date, q)
      expect(q.metadata["multiple-choice"]).to be(nil)
      expect(q.question_type).to eq("date")
    end

    it "with drop down" do
      drop_down = JSON.parse <<~JSON
        {
          "id": "hOoGYRWBvC0P",
          "title": "Drop Down Question text, single select",
          "ref": "5cff345f-4341-420b-bbd7-21e3a3915560",
          "properties": {
            "alphabetical_order": false,
            "choices": [
              {
                "label": "Drop down choice one text"
              },
              {
                "label": "Drop down choice two text"
              }
            ]
          },
          "validations": {
            "required": false
          },
          "type": "dropdown"
        }
      JSON

      q = Questionnaire::Question.new(metadata: {})
      TypeformService::TypeformWebMapper.map_question(drop_down, q)
      expect(q.metadata["multiple-choice"]["choices"].length).to be(2)
      expect(q.metadata["multiple-choice"]["multiple"]).to be(false)

      # checking first and last
      expect(q.metadata["multiple-choice"]["choices"][0]["label"]).to eq("Drop down choice one text")
      expect(q.metadata["multiple-choice"]["choices"][0]["value"]).to eq("Drop down choice one text")
      expect(q.metadata["multiple-choice"]["choices"][0]["position"]).to eq(0)

      expect(q.metadata["multiple-choice"]["choices"][1]["label"]).to eq("Drop down choice two text")
      expect(q.metadata["multiple-choice"]["choices"][1]["value"]).to eq("Drop down choice two text")
      expect(q.metadata["multiple-choice"]["choices"][1]["position"]).to eq(1)
      expect(q.metadata["text"]).to be(nil)
      expect(q.required).to be(false)
    end
  end
end
