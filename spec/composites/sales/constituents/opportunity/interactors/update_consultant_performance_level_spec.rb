# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Interactors::UpdateConsultantPerformanceLevel do
  let(:admin) { create :admin, role: create(:role), access_flags: ["sales_consultation"] }
  let(:category) { create :category }
  let(:performance_level) { "c" }
  let(:performace_row) { { admin.id => { id: 1, consultant_id: admin.id, performance_level: {} } } }

  before do
    allow_any_instance_of(Sales::Constituents::Opportunity::Repositories::MonthlyAdminPerformancesRepository)
      .to receive(:load_latest_performance_matrix_for)
      .and_return(performace_row)
  end

  describe "#call" do
    context "when consultant has sales_consultation grants" do
      it "triggers 'save!' repo method" do
        expect_any_instance_of(
          Sales::Constituents::Opportunity::Repositories::MonthlyAdminPerformancesRepository
        ).to receive(:save!).with(
          { performance_level: { category.ident => performance_level } }, 1
        )

        subject.call(consultant_id: admin.id, performance_level: performance_level, category_ident: category.ident)
      end
    end

    context "when consultant does not have sales_consultation grants" do
      before do
        admin.update!(access_flags: [])
      end

      it "triggers 'update_performance_level!' repo method" do
        expect_any_instance_of(
          Sales::Constituents::Opportunity::Repositories::MonthlyAdminPerformancesRepository
        ).not_to receive(:save!)

        subject.call(consultant_id: admin.id)
      end
    end
  end
end
