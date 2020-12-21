# frozen_string_literal: true

require "rails_helper"
require "./spec/fixtures/sample_ops_report_generator"

RSpec.describe ::Domain::Ops::Report::Runner, :integration do
  describe "#run" do
    let(:report_name) { "Sample Report" }
    let(:sample_config) do
      {
        name: report_name,
        class: SampleOpsReportGenerator.name
      }
    end

    context "when name and class are passed in" do
      it "OpsReport record with correct name is created" do
        expect { ::Domain::Ops::Report::Runner.run(sample_config) }
          .to change { OpsReport.where(name: report_name).count }.by(1)
      end

      it "generates csv report with expected properties" do
        Timecop.freeze(Time.zone.parse("01/01/2020")) do
          ::Domain::Ops::Report::Runner.run(sample_config)
        end
        ops_report = OpsReport.find_by(name: report_name).file
        file_content = File.read(ActiveStorage::Blob.service.path_for(ops_report.key))

        expect(ops_report.filename.to_s).to eq("ops_report_sample_report_01_01_2020_00_00.csv")
        expect(ops_report.content_type).to eq("text/csv")
        expect(file_content).to eq(
          "      name, email, location\n      Marshall Mathers, slimshady@drdre.com, 8 Mile Detroit\n"
        )
      end
    end

    context "when retry is passed in as false and report generation fails" do
      let(:invalid_config) { sample_config.merge(class: "invalid", retry: false) }

      it "does not raise error" do
        expect { ::Domain::Ops::Report::Runner.run(invalid_config) }
          .not_to raise_error
      end

      it "log error and trigger Sentry event" do
        expect_any_instance_of(::Logger).to receive(:error).twice
        expect(Raven).to receive(:capture_exception)

        ::Domain::Ops::Report::Runner.run(invalid_config)
      end
    end

    context "when retry is passed in as nil and report generation fails" do
      let(:invalid_config) { sample_config.merge(class: "invalid") }

      it "log error and raise exception" do
        expect_any_instance_of(::Logger).to receive(:error).twice
        expect(Raven).to receive(:capture_exception)

        expect { ::Domain::Ops::Report::Runner.run(invalid_config) }.to raise_exception(NameError)
      end
    end
  end
end
