# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Ops::Report::Scheduler do
  describe ".start" do
    let(:name) { "opportunities_wo_appointment" }
    let(:klass) { "Domain::Reports::Marketing::OpportunitiesWoAppointmentCsv" }

    context "when scheduler is executed after 01:00 AM" do
      it "logs a warning" do
        Timecop.freeze(Time.current.change(hour: 0o2)) do
          expect_any_instance_of(::Logger).to receive(:warn).with(
            "Report::Scheduler can only schedule reports for the same day !"\
            "If report scheduling time is in past, report gets generated immediately !"
          )
          Domain::Ops::Report::Scheduler.new
        end
      end
    end

    context "when valid report exists in configuration" do
      let(:reports) do
        [
          {
            name: name,
            class: klass,
            time: "07:00"
          }
        ]
      end

      before do
        allow_any_instance_of(described_class).to receive(:reports_to_be_scheduled).and_return(reports)
      end

      it "schedules Report::RunnerJob with correct arguments" do
        assert_enqueued_with(
          job: Ops::Report::RunnerJob,
          args: [reports.first],
          at: Time.current.change(hour: 7),
          queue: "ops_report_generation"
        ) do
          Domain::Ops::Report::Scheduler.start
        end
      end
    end

    context "when valid report exists matching current day of week" do
      let(:reports) do
        [
          {
            name:  name,
            class:  klass,
            time: "07:00",
            days: "123"
          }
        ]
      end

      context "on a valid day of the week" do
        before do
          allow_any_instance_of(described_class).to receive(:reports_to_be_scheduled).and_return(reports)
          Timecop.freeze(Time.zone.local(2020, 9, 1))
        end

        after do
          Timecop.return
        end

        it "schedules Report::RunnerJob with correct arguments" do
          assert_enqueued_with(
            job: Ops::Report::RunnerJob,
            args: [reports.first],
            at: Time.current.change(hour: 7),
            queue: "ops_report_generation"
          ) do
            Domain::Ops::Report::Scheduler.start
          end
        end
      end

      context "on an invalid day of week" do
        before do
          allow_any_instance_of(described_class).to receive(:reports_to_be_scheduled).and_return(reports)
          Timecop.freeze(Time.zone.local(2020, 9, 4))
        end

        after do
          Timecop.return
        end

        it "does not schedule the Report::RunnerJob" do
          assert_no_enqueued_jobs do
            Domain::Ops::Report::Scheduler.start
          end
        end
      end
    end

    context "when valid report exists in configuration but another env" do
      let(:reports) do
        [
          {
            name:  name,
            class:  klass,
            time: "07:00",
            environment: "fr"
          }
        ]
      end

      before do
        allow(Internationalization).to receive(:locale).and_return("de")
        allow_any_instance_of(described_class).to receive(:configuration).and_return(
          { reports: reports, config: { report_lifetime: 1 } }
        )
      end

      it "does't schedules Report::RunnerJob" do
        Domain::Ops::Report::Scheduler.start
        assert_no_enqueued_jobs
      end
    end

    context "when invalid report exists in configuration" do
      let(:rogue_reports) do
        [
          {
            name: "Year 2050, a developer at Clark did not read documentation and",
            class: "added incorrect scheduling time in OpsReport configuration.",
            time: nil
          },
          {
            name:  name,
            class:  klass,
            time: "07:00"
          }
        ]
      end

      before do
        allow_any_instance_of(
          described_class
        ).to receive(:reports_to_be_scheduled).and_return(rogue_reports)
      end

      it "Report::Scheduler does not crash and burn(Exception)" do
        expect { Domain::Ops::Report::Scheduler.start }.not_to raise_exception
      end

      it "correct reporting job gets scheduled" do
        assert_enqueued_with(
          job: Ops::Report::RunnerJob,
          args: [rogue_reports.last],
          at: Time.current.change(hour: 7),
          queue: "ops_report_generation"
        ) do
          Domain::Ops::Report::Scheduler.start
        end
      end

      it "send Sentry event" do
        expect(::Raven).to receive(:capture_exception)

        Domain::Ops::Report::Scheduler.start
      end

      it "logs error in logger" do
        expect_any_instance_of(::Logger).to receive(:error).twice

        Domain::Ops::Report::Scheduler.start
      end
    end

    context "when stale reports exist" do
      let!(:stale_report) { create(:ops_report, created_at: 1.year.ago) }
      let!(:fresh_report) { create(:ops_report) }

      it "deletes only stale reports" do
        expect { Domain::Ops::Report::Scheduler.start }.to change(OpsReport, :count).from(2).to(1)

        expect(OpsReport.pluck(:id)).to eq([fresh_report.id])
      end
    end
  end
end
