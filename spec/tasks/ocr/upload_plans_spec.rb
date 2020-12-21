# frozen_string_literal: true

require "rails_helper"

RSpec.describe "rake ocr:upload_plans", :integration, type: :task do
  let(:ocr_service_double) { instance_double(::OCR::Service) }
  let!(:plans) { create_list(:plan, 2, plan_state_begin: Date.new(2018, 1)) }
  let!(:plan_without_plan_state) { create(:plan, plan_state_begin: nil) }

  it_behaves_like "a ocr data uploader" do
    let(:data) do
      plans.map do |plan|
        [plan.ident, plan.name, plan.plan_state_begin.strftime("%m/%y"), plan.category.name, plan.subcompany.ident]
      end
    end
    let(:table) { ::OCR::MasterData::Schema::PLAN_TABLE }
    let(:columns) { ::OCR::MasterData::Schema::PLAN_COLUMNS }
  end
end
