# frozen_string_literal: true

require "rails_helper"
require "composites/sales"

RSpec.describe Sales::Constituents::Opportunity::Repositories::MonthlyAdminPerformancesRepository, :integration do
  let(:repository) { described_class.new }
  let(:first_admin) { create(:admin) }
  let(:second_admin) { create(:admin) }
  let(:first_admin_performances) {
    create_list(:monthly_admin_performance, 4, consultant_id: first_admin.id, algo_version: default_version)
  }
  let(:second_admin_performances) {
    create_list(:monthly_admin_performance, 4, consultant_id: second_admin.id, algo_version: default_version)
  }
  let(:default_version) { "default_version" }

  before do
    allow(Settings.aoa).to receive(:current_version).and_return(default_version)
  end

  after do
    allow(Settings.aoa).to receive(:current_version).and_call_original
  end

  def check_for_keys(result)
    expect(result.keys.sort)
      .to eq(%i[consultant_id performance_level revenue open_opportunities open_opportunities_category_counts
                calculation_date performance_matrix id].sort)
  end

  def check_result_with_object(result, object, category_ident=nil)
    check_for_keys(result)
    expect([
             result[:consultant_id],
             result[:performance_level],
             result[:revenue],
             result[:open_opportunities],
             result[:open_opportunities_category_counts],
             result[:calculation_date],
             result[:performance_matrix]
           ]).to eq([
                      object.consultant_id,
                      category_ident ? object.performance_level[category_ident] : object.performance_level,
                      object.revenue,
                      object.open_opportunities,
                      object.open_opportunities_category_counts,
                      object.calculation_date,
                      object.performance_matrix.transform_keys(&:to_i).transform_values { |v| v.transform_keys(&:to_i) }
                    ])
  end

  describe "#load_latest_performance_matrix_for" do
    context "when no ids passed" do
      it "returns the latest record for all admins have monthly performance records" do
        first_latest = first_admin_performances.max_by(&:calculation_date)
        second_latest = second_admin_performances.max_by(&:calculation_date)
        result = repository.load_latest_performance_matrix_for(default_version)
        expect(result.keys.sort).to eq([first_admin.id, second_admin.id].sort)
        check_result_with_object(result[first_admin.id], first_latest)
        check_result_with_object(result[second_admin.id], second_latest)
      end
    end

    context "when the passed consultant id has monthly performance records" do
      it "returns the latest record for passed admin ids" do
        first_admin_latest = first_admin_performances.max_by(&:calculation_date)
        second_admin_performances
        result = repository.load_latest_performance_matrix_for(default_version, first_admin.id)
        expect(result.keys).to eq([first_admin.id])
        check_result_with_object(result[first_admin.id], first_admin_latest)
      end
    end

    context "when the passed consultant id doesn't have monthly performance records" do
      it "returns passed admin ids in the hash with value nil" do
        first_admin_performances
        result = repository.load_latest_performance_matrix_for(default_version, second_admin.id)
        expect(result.keys).to eq([second_admin.id])
        expect(result[second_admin.id]).to be_nil
      end
    end

    context "category ident is passed" do
      before { first_admin_performances.last.update!(performance_level: { abc: "A" }) }

      it "returns the latest record having performance level for given category" do
        category_ident = "abc"
        result = repository.load_latest_performance_matrix_for(default_version, [], category_ident)
        expect(result.size).to eq 1
        check_result_with_object(
          result[first_admin_performances.last.consultant_id],
          first_admin_performances.last,
          category_ident
        )
      end
    end

    context "nil is passed as category ident" do
      it "returns the latest record for all admins" do
        first_admin_performances
        second_admin_performances
        expect(repository.load_latest_performance_matrix_for(default_version, [], nil).size).to eq 2
      end
    end
  end

  describe "#count_performance_matrices_for" do
    context "when no ids passed" do
      it "returns the number of monthly performance records for each admin" do
        first_admin_performances
        second_admin_performances
        result = repository.count_performance_matrices_for(default_version)
        expect(result.keys.sort).to eq([first_admin.id, second_admin.id].sort)
        expect(result[first_admin.id]).to eq(4)
        expect(result[second_admin.id]).to eq(4)
      end
    end

    context "when the passed consultant id has monthly performance records" do
      it "returns the number of monthly performance records for passed admin ids" do
        first_admin_performances
        second_admin_performances
        result = repository.count_performance_matrices_for(default_version, first_admin.id)
        expect(result.keys).to eq([first_admin.id])
        expect(result[first_admin.id]).to eq(4)
      end
    end

    context "when the passed consultant id doesn't have monthly performance records" do
      it "returns passed admin ids in the hash with value 0" do
        first_admin_performances
        result = repository.count_performance_matrices_for(default_version, second_admin.id)
        expect(result.keys).to eq([second_admin.id])
        expect(result[second_admin.id]).to eq(0)
      end
    end
  end

  describe "#save!" do
    let(:data_to_save) {
      {
        consultant_id: second_admin.id,
        performance_level: {},
        open_opportunities: 20,
        open_opportunities_category_counts: { Ident2: 20 },
        calculation_date: DateTime.now.beginning_of_month + 10.days,
        revenue: Faker::Number.between.floor(3),
        performance_matrix: {},
        algo_version: default_version
      }
    }

    context "update already existing monthly admin performance record" do
      let(:monthly_admin_performance) { create(:monthly_admin_performance, consultant_id: first_admin.id) }

      it "saves only allowed parameters to be saved" do
        subject = repository.save!(data_to_save, monthly_admin_performance.id)
        expect(subject.consultant_id).to eq(first_admin.id)
        expect(subject.performance_level).to eq(data_to_save[:performance_level])
        expect(subject.open_opportunities).to eq(data_to_save[:open_opportunities])
        expect(subject.open_opportunities_category_counts.symbolize_keys)
          .to eq(data_to_save[:open_opportunities_category_counts])
        expect(subject.revenue).to eq(data_to_save[:revenue])
        expect(subject.calculation_date).not_to eq(data_to_save[:calculation_date])
        expect(subject.performance_matrix).not_to eq(data_to_save[:performance_matrix])
      end
    end

    context "new already existing monthly admin performance record" do
      it "can create with only allowed parameters" do
        subject = repository.save!(data_to_save)
        expect(subject[:consultant_id]).to eq(data_to_save[:consultant_id])
        expect(subject[:performance_level]).to eq(data_to_save[:performance_level])
        expect(subject[:open_opportunities]).to eq(data_to_save[:open_opportunities])
        expect(subject[:open_opportunities_category_counts].symbolize_keys)
          .to eq(data_to_save[:open_opportunities_category_counts])
        expect(subject[:revenue]).to eq(data_to_save[:revenue])
        expect(subject[:calculation_date]).to eq(data_to_save[:calculation_date])
        expect(subject[:performance_matrix]).to eq(data_to_save[:performance_matrix])
      end
    end
  end
end
