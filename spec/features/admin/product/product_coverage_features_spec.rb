# frozen_string_literal: true

require "rails_helper"
require "support/features/coverage_helpers"

RSpec.describe "Product coverage features management", :slow, :browser, type: :feature do
  let(:resource) { create(:product) }

  before do
    login_super_admin
  end

  describe "edit" do
    context "when product category contains coverage feature" do
      it_behaves_like "a coverage feature", "Feature", type: "Boolean", input_type: :select, value: "Ja"

      it_behaves_like "a coverage feature", "Feature",
                      type: "AccountingTransactionType", input_type: :select, value: "Folgeprovision"

      it_behaves_like "a coverage feature", "Feature", type: "CallTypes", input_type: :select, value: "Videocall"

      it_behaves_like "a coverage feature", "Feature",
                      type: "Date", input_type: :date, value: Time.zone.today.strftime("%d.%m.%Y")

      it_behaves_like "a coverage feature", "Feature",
                      type: "FamilyStatus", input_type: :select, value: "Familie mit Kindern"

      it_behaves_like "a coverage feature", "Feature",
                      type: "FormOfPayment", input_type: :select, value: "vierteljährlich"

      it_behaves_like "a coverage feature", "Feature", type: "HouseType", input_type: :select, value: "HRMFH"

      it_behaves_like "a coverage feature", "Feature", type: "InlandAbroad", input_type: :select, value: "Ausland"

      it_behaves_like "a coverage feature", "Feature", type: "InsuredLossCount", input_type: :select, value: "2 Schäden"

      it_behaves_like "a coverage feature", "Feature", type: "Int", input_type: :int, value: "1"

      it_behaves_like "a coverage feature", "Feature", type: "MeansOfPayment", input_type: :select, value: "Lastschrift"

      it_behaves_like "a coverage feature", "Feature", type: "Money", input_type: :money, value: "100"

      it_behaves_like "a coverage feature", "Feature",
                      type: "ProfessionalEducationGrade", input_type: :select, value: "Bachelor"

      it_behaves_like "a coverage feature", "Feature",
                      type: "ProfessionalStatus", input_type: :select, value: "Angestellter"

      it_behaves_like "a coverage feature", "Feature", type: "Rating", input_type: :select, value: "★☆☆☆☆"

      it_behaves_like "a coverage feature", "Feature", type: "Text", input_type: :text, value: "Feature Text"
    end
  end
end
