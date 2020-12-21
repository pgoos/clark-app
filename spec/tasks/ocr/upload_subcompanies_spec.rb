# frozen_string_literal: true

require "rails_helper"

RSpec.describe "rake ocr:upload_subcompanies", integration: true, type: :task do
  let(:ocr_service_double) { instance_double(::OCR::Service) }
  let(:plan1) { create(:plan, plan_state_begin: 1.year.ago) }
  let(:plan2) { create(:plan, plan_state_begin: 2.years.ago) }
  let(:plan3) { create(:plan, plan_state_begin: nil) }
  let(:plan4) { create(:plan, plan_state_begin: nil) }

  let!(:subcompany1) { create(:subcompany, plans: [plan1], street: nil, zipcode: nil, city: nil) }
  let!(:subcompany2) { create(:subcompany, plans: [plan2, plan3]) }
  let!(:subcompany3) { create(:subcompany, plans: [plan4]) }

  it_behaves_like "a ocr data uploader" do
    let(:data) do
      first = [
        subcompany1.ident,
        subcompany1.name,
        subcompany1.company.info["info_phone"],
        subcompany1.company.info["info_email"],
        "#{subcompany1.company.street}, #{subcompany1.company.house_number}",
        subcompany1.company.zipcode,
        subcompany1.company.city
      ]
      second = [
        subcompany2.ident,
        subcompany2.name,
        subcompany2.company.info["info_phone"],
        subcompany2.company.info["info_email"],
        "#{subcompany2.street}, #{subcompany2.house_number}",
        subcompany2.zipcode,
        subcompany2.city
      ]

      [first, second]
    end
    let(:table) { ::OCR::MasterData::Schema::SUBCOMPANY_TABLE }
    let(:columns) { ::OCR::MasterData::Schema::SUBCOMPANY_COLUMNS }
  end
end
