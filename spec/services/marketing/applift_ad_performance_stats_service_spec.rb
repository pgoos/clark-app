# frozen_string_literal: true

require "rails_helper"

describe Marketing::AppliftAdPerformanceStatsService do
  Time.use_zone("Europe/Berlin") do
    let(:start_date) { Date.new(2016, 2, 16) }
    let(:end_date) { Date.new(2016, 2, 17) }
    let(:campaign_name_1) { "Clark Versicherungen (Android, Free, DE, 50MB, w/capping, NRB)" }
    let(:adgroup_name_1) { "-" }
    let(:service) { Marketing::AppliftAdPerformanceStatsService.instance }
    let(:utc_offset) do
      start_offset = UtcOffsetCalculator.utc_day_start_offset_for_date(end_date)
      end_offset   = UtcOffsetCalculator.utc_day_end_offset_for_date(end_date)
      [start_offset, end_offset]
    end
    let(:fake_exchange_rate) do
      CurrencyExchangeRateService::CurrencylayerFakeService::FAKE_USDEUR_RATE
    end

    context "aggregate logs" do
      it "should request the performance stats for a given date range" do
        expect(described_class::AppliftStatsFakeRemoteService).to receive(:get_stats)
          .at_least(:once) { response_json_fixture }
        daily_performances = []
        service.daily_performances_for_date_range(start_date, end_date) do |ad_performance_entry|
          daily_performances << ad_performance_entry
        end

        # calculated by multiplying single entries with the exchange rate, summing up rounded cents:
        expected_cost_first_affiliate = 936

        expected_first_utc_time_start = DateTime.strptime(
          "#{start_date} 00:00:00.000000000 +#{utc_offset[0]}", "%Y-%m-%d %H:%M:%S.%N %z"
        ).utc
        expected_first_utc_time_end = DateTime.strptime(
          "#{start_date} 23:59:59.999999999 +#{utc_offset[1]}", "%Y-%m-%d %H:%M:%S.%N %z"
        ).utc

        expected_second_utc_time_start = DateTime.strptime(
          "#{end_date} 00:00:00.000000000 +#{utc_offset[0]}", "%Y-%m-%d %H:%M:%S.%N %z"
        ).utc
        expected_second_utc_time_end = DateTime.strptime(
          "#{end_date} 23:59:59.999999999 +#{utc_offset[1]}", "%Y-%m-%d %H:%M:%S.%N %z"
        ).utc

        expect(daily_performances[0]).to eq(
          ad_provider:           Marketing::AppliftAdPerformanceStatsService::AD_PROVIDER_NAME,
          campaign_name:         campaign_name_1,
          adgroup_name:          adgroup_name_1,
          start_report_interval: expected_first_utc_time_start,
          end_report_interval:   expected_first_utc_time_end,
          cost_cents:            expected_cost_first_affiliate,
          cost_currency:         "EUR"
        )
        expect(daily_performances[2]).to eq(
          ad_provider:           Marketing::AppliftAdPerformanceStatsService::AD_PROVIDER_NAME,
          campaign_name:         campaign_name_1,
          adgroup_name:          adgroup_name_1,
          start_report_interval: expected_second_utc_time_start,
          end_report_interval:   expected_second_utc_time_end,
          cost_cents:            expected_cost_first_affiliate,
          cost_currency:         "EUR"
        )
      end
    end

    it "should know the first reporting date and time" do
      raw_time = "2016-01-08 00:00:00.000000000 +#{utc_offset[0]}"
      expected_datetime = DateTime.strptime(raw_time, "%Y-%m-%d %H:%M:%S.%N %z").utc
      expect(service.reporting_ever_starts_at).to eq(expected_datetime)
    end

    context "inspect existing entries" do
      let(:today) { Date.new(2016, 1, 12) }

      it "should calculate the update start and end dates" do
        Timecop.freeze(today) do
          day_after_last_log = service.reporting_ever_starts_at.in_time_zone.to_date
          yesterday = today.advance(days: -1)
          expect(service.calc_update_dates).to match_array([day_after_last_log, yesterday])
        end
      end

      it "should use the first day without log entries as start date" do
        Timecop.freeze(today) do
          create(
            :advertisement_performance_log,
            ad_provider:           described_class::AD_PROVIDER_NAME,
            campaign_name:         campaign_name_1,
            adgroup_name:          adgroup_name_1,
            start_report_interval: service.reporting_ever_starts_at,
            end_report_interval:   service.reporting_ever_starts_at
          )
          day_after_last = service.reporting_ever_starts_at.in_time_zone.to_date.advance(days: 1)
          yesterday = today.advance(days: -1)
          expect(service.calc_update_dates).to match_array([day_after_last, yesterday])
        end
      end

      it "should ignore other ad_providers" do
        Timecop.freeze(today) do
          create(:advertisement_performance_log,
                             start_report_interval: service.reporting_ever_starts_at,
                             end_report_interval: service.reporting_ever_starts_at
          )
          day_after_last_log = service.reporting_ever_starts_at.in_time_zone.to_date
          yesterday = today.advance(days: -1)
          expect(service.calc_update_dates).to match_array([day_after_last_log, yesterday])
        end
      end
    end

    context "remote service http error handling" do
      let(:fake_response) do
        double(
          message: "fake message",
          response_body_permitted?: true,
          body: '{"fake body" : "fake value", "success" : true}',
          code: "200"
        )
      end
      let(:remote_service) { described_class::AppliftStatsRemoteService }
      let(:statistics_date) { Date.new(2016, 2, 16) }

      before do
        allow(Net::HTTP).to receive(:get_response) { fake_response }
      end

      it "should raise, if the request did not succeed for client reasons" do
        allow(fake_response).to receive(:code) { "400" }
        expect {
          remote_service.get_stats(statistics_date, statistics_date)
        }.to raise_error(
          "Http request failed! Response code: '#{fake_response.code}', " +
          "response message: '#{fake_response.message}', response body: '#{fake_response.body}'"
        )
      end

      it "should raise, if the request did not succeed for server reasons" do
        allow(fake_response).to receive(:code) { "500" }
        expect {
          remote_service.get_stats(statistics_date, statistics_date)
        }.to raise_error(
          "Http request failed! Response code: '#{fake_response.code}', " +
          "response message: '#{fake_response.message}', response body: '#{fake_response.body}'"
        )
      end

      it "should succeed, if the request returned a status code 200" do
        allow(fake_response).to receive(:code) { "200" }
        expect {
          remote_service.get_stats(statistics_date, statistics_date)
        }.not_to raise_error
      end

      it "should succeed, if the request returned a status code 304" do
        allow(fake_response).to receive(:code) { "304" }
        expect {
          remote_service.get_stats(statistics_date, statistics_date)
        }.not_to raise_error
      end

      it "should raise an error, if within the response success == false" do
        allow(fake_response).to receive(:body) { '{"success" : false }' }
        expect {
          remote_service.get_stats(statistics_date, statistics_date)
        }.to raise_error("request failed! '{\"success\"=>false}'")
      end
    end

    def response_json_fixture
      stubbed_response = {
        "data"    => [
          {
            "date"        => start_date.to_s,
            "offer"       => campaign_name_1,
            "conversions" => "1",
            "cost"        => "$1.10"
          },
          {
            "date"        => start_date.to_s,
            "offer"       => campaign_name_1,
            "conversions" => "2",
            "cost"        => "$2.20"
          },
          {
            "date"        => start_date.to_s,
            "offer"       => campaign_name_1,
            "conversions" => "3",
            "cost"        => "$3.30"
          },
          {
            "date"        => start_date.to_s,
            "offer"       => campaign_name_1,
            "conversions" => "4",
            "cost"        => "$4.40"
          },
          {
            "date"        => start_date.to_s,
            "offer"       => "Other Offer",
            "conversions" => "1",
            "cost"        => "$1.23"
          },
          {
            "date"        => end_date.to_s,
            "offer"       => campaign_name_1,
            "conversions" => "1",
            "cost"        => "$1.10"
          },
          {
            "date"        => end_date.to_s,
            "offer"       => campaign_name_1,
            "conversions" => "2",
            "cost"        => "$2.20"
          },
          {
            "date"        => end_date.to_s,
            "offer"       => campaign_name_1,
            "conversions" => "3",
            "cost"        => "$3.30"
          },
          {
            "date"        => end_date.to_s,
            "offer"       => campaign_name_1,
            "conversions" => "4",
            "cost"        => "$4.40"
          },
          {
            "date"        => end_date.to_s,
            "offer"       => "Other Offer",
            "conversions" => "1",
            "cost"        => "$4.56"
          },
        ],
        "success" => true
      }

      stubbed_response["totalNumRows"] = stubbed_response["data"].size
      stubbed_response
    end
  end
end
