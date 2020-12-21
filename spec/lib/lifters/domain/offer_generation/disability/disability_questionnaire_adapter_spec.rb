# frozen_string_literal: true

RSpec.describe Domain::OfferGeneration::Disability::DisabilityQuestionnaireAdapter do
  subject { described_class.new(response) }

  let(:quest_id) { described_class::QUESTIONNAIRE_ID }
  let(:response) do
    instance_double(
      Questionnaire::Response,
      questionnaire_identifier: quest_id
    )
  end

  it "should match to the questionnaire response's questionnaire" do
    wrong_identifier = "wrong_#{rand}"
    allow(response).to receive(:questionnaire_identifier).and_return(wrong_identifier)
    expect {
      subject
    }.to raise_error("Expected questionnaire '#{quest_id}' did not match '#{wrong_identifier}'")
  end

  context "#smoker?" do
    let(:smoker_question_id) { "yesno_33559841" }
    it "should be true if response to yesno_33559841 is 'Ja'" do
      allow(response).to receive(:extract_normalized_answer).with(smoker_question_id)
        .and_return("Ja")
      expect(subject.smoker?).to be(true)
    end

    it "should be false if response to yesno_33559841 is 'Nein'" do
      allow(response).to receive(:extract_normalized_answer).with(smoker_question_id)
        .and_return("Nein")
      expect(subject.smoker?).to be(false)
    end
  end

  context "#employment" do
    let(:employment_question_id) { "textfield_33559847" }
    let(:expected_employment) { "Job Name #{rand}" }

    it "should read the employment" do
      allow(response).to receive(:extract_normalized_answer).with(employment_question_id)
        .and_return(expected_employment)
      expect(subject.employment).to eq(expected_employment)
    end

    it "should replace linefeeds with simple space" do
      allow(response).to receive(:extract_normalized_answer).with(employment_question_id)
        .and_return(expected_employment.tr(" ", "\n"))
      expect(subject.employment).to eq(expected_employment)
    end

    it "should replace carriage returns with simple space" do
      allow(response).to receive(:extract_normalized_answer).with(employment_question_id)
        .and_return(expected_employment.tr(" ", "\r"))
      expect(subject.employment).to eq(expected_employment)
    end

    it "should replace windows linebreaks with simple space" do
      allow(response).to receive(:extract_normalized_answer).with(employment_question_id)
        .and_return(expected_employment.tr(" ", "\r\n"))
      expect(subject.employment).to eq(expected_employment)
    end

    it "should replace tabs with simple space" do
      allow(response).to receive(:extract_normalized_answer).with(employment_question_id)
        .and_return(expected_employment.tr(" ", "\t"))
      expect(subject.employment).to eq(expected_employment)
    end
  end

  context "#professional_status" do
    let(:professional_status_question_id) { "list_33559837" }

    it "should read 'Angestellter' as employee" do
      allow(response).to receive(:extract_normalized_answer).with(professional_status_question_id)
        .and_return("Angestellter")
      expect(subject.professional_status).to eq(ValueTypes::ProfessionalStatus::EMPLOYEE)
    end

    it "should read 'Arbeitnehmer im öffentlichen Dienst' as civil service employee" do
      allow(response).to receive(:extract_normalized_answer).with(professional_status_question_id)
        .and_return("Arbeitnehmer im öffentlichen Dienst")
      expect(subject.professional_status).to eq(ValueTypes::ProfessionalStatus::CIVIL_SERVICE_EMPLOYEE)
    end

    it "should read 'Beamter' as official" do
      allow(response).to receive(:extract_normalized_answer).with(professional_status_question_id)
        .and_return("Beamter")
      expect(subject.professional_status).to eq(ValueTypes::ProfessionalStatus::OFFICIAL)
    end

    it "should read 'Freiberufler/ Selbständiger' as self employed" do
      allow(response).to receive(:extract_normalized_answer).with(professional_status_question_id)
        .and_return("Freiberufler/ Selbstständiger")
      expect(subject.professional_status).to eq(ValueTypes::ProfessionalStatus::SELF_EMPLOYED)
    end

    it "should read 'Auszubildender' as apprentice" do
      allow(response).to receive(:extract_normalized_answer).with(professional_status_question_id)
        .and_return("Auszubildender")
      expect(subject.professional_status).to eq(ValueTypes::ProfessionalStatus::APPRENTICE)
    end

    it "should read 'Nicht berufstätig' as unemployed" do
      allow(response).to receive(:extract_normalized_answer).with(professional_status_question_id)
        .and_return("Nicht berufstätig")
      expect(subject.professional_status).to eq(ValueTypes::ProfessionalStatus::UNEMPLOYED)
    end

    it "should read 'Student' as higher education student" do
      allow(response).to receive(:extract_normalized_answer).with(professional_status_question_id)
        .and_return("Student")
      expect(subject.professional_status).to eq(ValueTypes::ProfessionalStatus::HIGHER_EDUCATION_STUDENT)
    end

    it "should read 'Schüler' as school student" do
      allow(response).to receive(:extract_normalized_answer).with(professional_status_question_id)
        .and_return("Schüler")
      expect(subject.professional_status).to eq(ValueTypes::ProfessionalStatus::SCHOOL_STUDENT)
    end
  end

  context "#professional_education_grade" do
    let(:education_grade_question_id) { "list_33559839" }

    it "should read 'Schulabschluss'" do
      allow(response).to receive(:extract_normalized_answer).with(education_grade_question_id)
        .and_return("Schulabschluss")
      expect(subject.professional_education_grade)
        .to eq(nil)
    end

    it "should read 'Abgeschlossene Berufsausbildung'" do
      allow(response).to receive(:extract_normalized_answer).with(education_grade_question_id)
        .and_return("Abgeschlossene Berufsausbildung")
      expect(subject.professional_education_grade)
        .to eq(ValueTypes::ProfessionalEducationGrade::OFFICIALLY_RECOGNIZED_APPRENTICESHIP)
    end

    it "should read 'Bachelor'" do
      allow(response).to receive(:extract_normalized_answer).with(education_grade_question_id)
        .and_return("Bachelor")
      expect(subject.professional_education_grade)
        .to eq(ValueTypes::ProfessionalEducationGrade::BACHELOR)
    end

    it "should read 'Master'" do
      allow(response).to receive(:extract_normalized_answer).with(education_grade_question_id)
        .and_return("Master")
      expect(subject.professional_education_grade)
        .to eq(ValueTypes::ProfessionalEducationGrade::MASTER)
    end

    it "should read 'Diplom'" do
      allow(response).to receive(:extract_normalized_answer).with(education_grade_question_id)
        .and_return("Diplom")
      expect(subject.professional_education_grade)
        .to eq(ValueTypes::ProfessionalEducationGrade::GERMAN_DIPLOMA)
    end

    it "should read 'Promotion'" do
      allow(response).to receive(:extract_normalized_answer).with(education_grade_question_id)
        .and_return("Promotion")
      expect(subject.professional_education_grade)
        .to eq(ValueTypes::ProfessionalEducationGrade::PHD)
    end
  end

  context "#team_lead?" do
    let(:team_lead_question_id) { "yesno_33559843" }
    it "should be true if response to yesno_33559843 is 'Ja'" do
      allow(response).to receive(:extract_normalized_answer).with(team_lead_question_id)
        .and_return("Ja")
      expect(subject.team_lead?).to be(true)
    end

    it "should be false if response to yesno_33559843 is 'Nein'" do
      allow(response).to receive(:extract_normalized_answer).with(team_lead_question_id)
        .and_return("Nein")
      expect(subject.team_lead?).to be(false)
    end
  end

  context "#subordinate_staff_count" do
    let(:subordinate_staff_count_question_id) { "number_33559852" }
    let(:expected_staff_count) { (rand * 100).round + 1 }

    it "should return 0 if the answer to number_33559852 is nil" do
      allow(response).to receive(:extract_normalized_answer)
        .with(subordinate_staff_count_question_id)
        .and_return(nil)
      expect(subject.subordinate_staff_count).to eq(0)
    end

    it "should return 0 if the answer to number_33559852 is empty" do
      allow(response).to receive(:extract_normalized_answer)
        .with(subordinate_staff_count_question_id)
        .and_return("")
      expect(subject.subordinate_staff_count).to eq(0)
    end

    it "should return the integer if given to number_33559852" do
      allow(response).to receive(:extract_normalized_answer)
        .with(subordinate_staff_count_question_id)
        .and_return(expected_staff_count)
      expect(subject.subordinate_staff_count).to eq(expected_staff_count)
    end

    it "should fail for an invalid answer to number_33559852" do
      wrong_value = "not a number"
      allow(response).to receive(:extract_normalized_answer)
        .with(subordinate_staff_count_question_id)
        .and_return(wrong_value)
      expect {
        subject.subordinate_staff_count
      }.to raise_error("invalid value for Integer(): \"#{wrong_value}\"")
    end
  end

  context "office_work_percentage" do
    let(:percentage_question_id) { "number_33559853" }
    let(:percentage) { (rand * 101).floor }

    it "should parse 0 <= n <= 100 at number_33559853 to integer n" do
      allow(response).to receive(:extract_normalized_answer)
        .with(percentage_question_id)
        .and_return(percentage.to_s)
      expect(subject.office_work_percentage).to eq(percentage)
    end

    it "returns nil for negative values" do
      allow(response).to receive(:extract_normalized_answer)
        .with(percentage_question_id)
        .and_return("-#{percentage}")
      expect(subject.office_work_percentage).to be_nil
    end

    it "returns nil for values > 100" do
      allow(response).to receive(:extract_normalized_answer)
        .with(percentage_question_id)
        .and_return(101.to_s)
      expect(subject.office_work_percentage).to be_nil
    end

    it "allows a '%' postfix" do
      allow(response).to receive(:extract_normalized_answer)
        .with(percentage_question_id)
        .and_return("#{percentage}%")
      expect(subject.office_work_percentage).to eq(percentage)
    end

    it "allows 'Prozent' as postfix" do
      allow(response).to receive(:extract_normalized_answer)
        .with(percentage_question_id)
        .and_return("#{percentage}Prozent")
      expect(subject.office_work_percentage).to eq(percentage)
    end

    it "allows 'pROZENT' ignoring case as postfix" do
      allow(response).to receive(:extract_normalized_answer)
        .with(percentage_question_id)
        .and_return("#{percentage}pROZENT")
      expect(subject.office_work_percentage).to eq(percentage)
    end

    it "allows white space before percentage and unit" do
      allow(response).to receive(:extract_normalized_answer)
        .with(percentage_question_id)
        .and_return(" \r\n\n\t#{percentage}%")
      expect(subject.office_work_percentage).to eq(percentage)
    end

    it "allows white space between percentage and unit" do
      allow(response).to receive(:extract_normalized_answer)
        .with(percentage_question_id)
        .and_return("#{percentage} \r\n\n\t%")
      expect(subject.office_work_percentage).to eq(percentage)
    end

    it "allows white space after percentage and unit" do
      allow(response).to receive(:extract_normalized_answer)
        .with(percentage_question_id)
        .and_return("#{percentage} %\r\n\n\t")
      expect(subject.office_work_percentage).to eq(percentage)
    end

    it "returns nil if unidentified strings are contained as prefix" do
      allow(response).to receive(:extract_normalized_answer)
        .with(percentage_question_id)
        .and_return("a#{percentage}")
      expect(subject.office_work_percentage).to be_nil
    end

    it "returns nil if unidentified strings are contained as infix" do
      allow(response).to receive(:extract_normalized_answer)
        .with(percentage_question_id)
        .and_return("#{percentage}a%")
      expect(subject.office_work_percentage).to be_nil
    end

    it "returns nil if unidentified strings are contained as postfix" do
      allow(response).to receive(:extract_normalized_answer)
        .with(percentage_question_id)
        .and_return("#{percentage}a")
      expect(subject.office_work_percentage).to be_nil
    end

    it "returns nil if unidentified strings are contained as only sequence" do
      allow(response).to receive(:extract_normalized_answer)
        .with(percentage_question_id)
        .and_return("a")
      expect(subject.office_work_percentage).to be_nil
    end
  end

  context "gross_income" do
    let(:income_question_id) { "number_33559851" }
    let(:income) { (100_000 * rand).floor }
    let(:epsilon) do
      result = (100 * rand).floor
      result += 10 if result < 10
      result
    end

    it "should parse income at number_33559851 to float" do
      allow(response).to receive(:extract_normalized_answer)
        .with(income_question_id)
        .and_return(income.to_s)
      expect(subject.gross_income).to be_within(0.01).of(income)
    end

    it "allows a comma as a decimal separator" do
      allow(response).to receive(:extract_normalized_answer)
        .with(income_question_id)
        .and_return("#{income},#{epsilon}")
      expect(subject.gross_income).to be_within(0.01).of(income + (epsilon / 100.0))
    end

    it "allows a dot as thousands separator" do
      thousands = (rand * 999).floor
      hundreds = 456 # use a fixed value here to avoid leading zeroes
      income = (thousands * 1000) + hundreds
      allow(response).to receive(:extract_normalized_answer)
        .with(income_question_id)
        .and_return("#{thousands}.#{hundreds}")
      expect(subject.gross_income).to be_within(0.01).of(income)
    end

    it "returns nil for negative values" do
      allow(response).to receive(:extract_normalized_answer)
        .with(income_question_id)
        .and_return("-#{income}")
      expect(subject.gross_income).to be_nil
    end

    it "allows a '€' postfix" do
      skip "probably because of some change on money questions on questionnaires"
      allow(response).to receive(:extract_normalized_answer)
        .with(income_question_id)
        .and_return("#{income}€")
      expect(subject.gross_income).to be_within(0.01).of(income)
    end

    it "allows 'Euro' as postfix" do
      allow(response).to receive(:extract_normalized_answer)
        .with(income_question_id)
        .and_return("#{income}Euro")
      expect(subject.gross_income).to be_within(0.01).of(income)
    end

    it "allows 'eURO' ignoring case as postfix" do
      allow(response).to receive(:extract_normalized_answer)
        .with(income_question_id)
        .and_return("#{income}eURO")
      expect(subject.gross_income).to be_within(0.01).of(income)
    end

    it "allows white space before income and unit" do
      allow(response).to receive(:extract_normalized_answer)
        .with(income_question_id)
        .and_return(" \r\n\n\t#{income}€")
      expect(subject.gross_income).to be_within(0.01).of(income)
    end

    it "allows white space between income and unit" do
      allow(response).to receive(:extract_normalized_answer)
        .with(income_question_id)
        .and_return("#{income} \r\n\n\t€")
      expect(subject.gross_income).to be_within(0.01).of(income)
    end

    it "allows white space after income and unit" do
      allow(response).to receive(:extract_normalized_answer)
        .with(income_question_id)
        .and_return("#{income} €\r\n\n\t")
      expect(subject.gross_income).to be_within(0.01).of(income)
    end

    it "returns nil if unidentified strings are contained as prefix" do
      allow(response).to receive(:extract_normalized_answer)
        .with(income_question_id)
        .and_return("a#{income}")
      expect(subject.gross_income).to be_nil
    end

    it "returns nil if unidentified strings are contained as infix" do
      allow(response).to receive(:extract_normalized_answer)
        .with(income_question_id)
        .and_return("#{income}a€")
      expect(subject.gross_income).to be_nil
    end

    it "returns nil if unidentified strings are contained as postfix" do
      allow(response).to receive(:extract_normalized_answer)
        .with(income_question_id)
        .and_return("#{income}a")
      expect(subject.gross_income).to be_nil
    end

    it "returns nil if unidentified strings are contained as only sequence" do
      allow(response).to receive(:extract_normalized_answer)
        .with(income_question_id)
        .and_return("a")
      expect(subject.gross_income).to be_nil
    end
  end
end
