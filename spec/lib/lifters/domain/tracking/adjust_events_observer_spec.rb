# frozen_string_literal: true

require "rails_helper"

describe Domain::Tracking::AdjustEventsObserver do
  let(:ad_id) { Faker::Internet.device_token }
  let(:mandate) { create(:mandate, user: user) }
  let(:opportunity) { create(:opportunity, mandate: mandate) }
  let(:user) { create(:user, source_data: { "advertiser_ids" => { ad_id => "gps_adid" } }) }
  let(:android_source_data) { { "advertiser_ids" => { ad_id => "gps_adid" } } }
  let(:invalid_source_data) do
    {
      "advertiser_ids" => { Domain::Tracking::AdjustEventsObserver::ADVERTISER_NIL => "gps_adid" }
    }
  end
  let(:ios_source_data) { { "advertiser_ids" => { ad_id => "idfa" } } }

  describe "#send_adjust_hm_opportunity_created_48h" do
    let(:opportunity) { create(:opportunity, mandate: mandate) }

    it "does not send event if user does not have proper source data" do
      user.update(source_data: nil)

      expect(::Marketing::AdjustTrackingService).not_to receive(:track)
      described_class.send_adjust_hm_opportunity_created_48h(opportunity)
    end

    it "does not send event if advertiser is not valid" do
      user.update(source_data: invalid_source_data)

      expect(::Marketing::AdjustTrackingService).not_to receive(:track)
      described_class.send_adjust_hm_opportunity_created_48h(opportunity)
    end

    it "does not send event if mandate is older that 48 hours" do
      mandate.update(created_at: Time.now - 3.days)

      expect(::Marketing::AdjustTrackingService).not_to receive(:track)
      described_class.send_adjust_hm_opportunity_created_48h(opportunity)
    end

    it "does not send event if category is not high margin" do
      opportunity.category.update(margin_level: "low")

      expect(::Marketing::AdjustTrackingService).not_to receive(:track)
      described_class.send_adjust_hm_opportunity_created_48h(opportunity)
    end

    it "sends event if there is a valid subcompanies for company" do
      opportunity.category.update(margin_level: "high")

      Timecop.freeze do
        expect(::Marketing::AdjustTrackingService).to(
          receive(:track).with(activity_kind: "hm_opportunity_created_48h",
                               os_name: "android",
                               app_id: "de.clark",
                               device_event_time: DateTime.current,
                               advertiser_id: ad_id,
                               mandate_id: mandate.id,
                               revenue: 3700,
                               currency: "EUR")
        )

        described_class.send_adjust_hm_opportunity_created_48h(opportunity)
      end
    end
  end

  describe "#send_adjust_accept_tracking" do
    let(:clv) { (rand * 100).round }

    before do
      allow_any_instance_of(Domain::Reports::CustomerValue).to receive(:clv).and_return(clv)
    end

    it "sends tracking for correct data for iOS ad ids" do
      user.update(source_data: { advertiser_ids: { ad_id => "idfa" } })

      Timecop.freeze do
        expect(Marketing::AdjustTrackingService).to(
          receive(:track).with(activity_kind: "mandate_accepted",
                               os_name: "ios",
                               app_id: "1054790721",
                               device_event_time: DateTime.current,
                               advertiser_id: ad_id,
                               mandate_id: mandate.id,
                               revenue: clv,
                               currency: "EUR")
        )

        described_class.send_adjust_accept_tracking(mandate)
      end
    end

    it "sends tracking for correct data for android ad ids" do
      Timecop.freeze do
        expect(Marketing::AdjustTrackingService).to(
          receive(:track).with(activity_kind: "mandate_accepted",
                               os_name: "android",
                               app_id: "de.clark",
                               device_event_time: DateTime.current,
                               advertiser_id: ad_id,
                               mandate_id: mandate.id,
                               revenue: clv,
                               currency: "EUR")
        )

        described_class.send_adjust_accept_tracking(mandate)
      end
    end

    it "does not send out event when no source data is present" do
      user.update(source_data: nil)

      expect(Marketing::AdjustTrackingService).not_to receive(:track)
      described_class.send_adjust_accept_tracking(mandate)
    end

    it "does not send out event if advertiser is not valid" do
      user.update(source_data: invalid_source_data)

      expect(Marketing::AdjustTrackingService).not_to receive(:track)
      described_class.send_adjust_accept_tracking(mandate)
    end

    it "does not send out event when no advertiser_id is present" do
      user.update(source_data: { advertiser_ids: {} })

      expect(Marketing::AdjustTrackingService).not_to receive(:track)
      described_class.send_adjust_accept_tracking(mandate)
    end

    it "does not die when an exception occurs in the service (but notifies Sentry)" do
      expect(Raven).to receive(:capture_exception).with(RuntimeError)

      expect(Marketing::AdjustTrackingService)
        .to receive(:track).and_raise("something went wrong")

      expect { described_class.send_adjust_accept_tracking(mandate) }.not_to raise_error
    end
  end

  describe "#send_adjust_ptp_inquiry_created_48h" do
    let(:mandate) { create(:mandate, user: user, state: "accepted") }
    let(:inquiry) { create(:inquiry, mandate: mandate) }

    it "does not send event if user does not have proper source data" do
      user.update(source_data: nil)

      expect(Marketing::AdjustTrackingService).not_to receive(:track)
      described_class.send_adjust_ptp_inquiry_created_48h(inquiry.id)
    end

    it "does not send event if inquiry is already has been deleted" do
      inquiry.delete

      expect(Marketing::AdjustTrackingService).not_to receive(:track)
      described_class.send_adjust_ptp_inquiry_created_48h(inquiry.id)
    end

    it "does not send event if mandate is older that 48 hours" do
      mandate.update(created_at: Time.now - 3.days)

      expect(Marketing::AdjustTrackingService).not_to receive(:track)
      described_class.send_adjust_ptp_inquiry_created_48h(inquiry.id)
    end

    it "does not send event if mandate state is not accepted" do
      mandate.update(state: "in_progress")

      expect(Marketing::AdjustTrackingService).not_to receive(:track)
      described_class.send_adjust_ptp_inquiry_created_48h(inquiry.id)
    end

    context "when subcompany is nil" do
      let(:inquiry) { create(:inquiry, subcompany: nil, mandate: mandate) }

      it "does not send event if there is no valid subcompanies for company" do
        expect(Marketing::AdjustTrackingService).not_to receive(:track)
        described_class.send_adjust_ptp_inquiry_created_48h(inquiry.id)
      end

      it "sends event if there is a valid subcompanies for company" do
        inquiry.update(company: create(:company, subcompanies: [create(:subcompany, pools: ["POOL1"])]))

        Timecop.freeze do
          expect(Marketing::AdjustTrackingService).to(
            receive(:track).with(activity_kind: "ptp_inquiry_created_48h",
                                 os_name: "android",
                                 app_id: "de.clark",
                                 device_event_time: DateTime.current,
                                 advertiser_id: ad_id,
                                 mandate_id: mandate.id,
                                 revenue: described_class::PTP_INQUIRY_ESTIMATED_REVENUE,
                                 currency: "EUR")
          )

          described_class.send_adjust_ptp_inquiry_created_48h(inquiry.id)
        end
      end
    end

    context "when subcompany presents" do
      it "does not send event if subcompany's pool is empty" do
        inquiry.update(subcompany: create(:subcompany))

        expect(Marketing::AdjustTrackingService).not_to receive(:track)
        described_class.send_adjust_ptp_inquiry_created_48h(inquiry.id)
      end

      it "sends event if subcompany has valid pools" do
        inquiry.update(subcompany: create(:subcompany, pools: ["POOL1"]))

        Timecop.freeze do
          expect(Marketing::AdjustTrackingService).to(
            receive(:track).with(activity_kind: "ptp_inquiry_created_48h",
                                 os_name: "android",
                                 app_id: "de.clark",
                                 device_event_time: DateTime.current,
                                 advertiser_id: ad_id,
                                 mandate_id: mandate.id,
                                 revenue: described_class::PTP_INQUIRY_ESTIMATED_REVENUE,
                                 currency: "EUR")
          )

          described_class.send_adjust_ptp_inquiry_created_48h(inquiry.id)
        end
      end
    end
  end

  describe "#send_adjust_demand_check_finished_tracking" do
    it "sends tracking for correct data for iOS ad ids" do
      user.update(source_data: ios_source_data)

      Timecop.freeze do
        expect(Marketing::AdjustTrackingService).to(
          receive(:track).with(activity_kind: "demand_check_finished",
                               os_name: "ios",
                               app_id: "1054790721",
                               device_event_time: DateTime.current,
                               advertiser_id: ad_id,
                               mandate_id: mandate.id)
        )

        described_class.send_adjust_demand_check_finished_tracking(mandate)
      end
    end

    it "sends tracking for correct data for android ad ids" do
      Timecop.freeze do
        expect(Marketing::AdjustTrackingService).to(
          receive(:track).with(activity_kind: "demand_check_finished",
                               os_name: "android",
                               app_id: "de.clark",
                               device_event_time: DateTime.current,
                               advertiser_id: ad_id,
                               mandate_id: mandate.id)
        )

        described_class.send_adjust_demand_check_finished_tracking(mandate)
      end
    end

    it "does not send out event when no source data is present" do
      user.update(source_data: nil)

      expect(Marketing::AdjustTrackingService).not_to receive(:track)
      described_class.send_adjust_demand_check_finished_tracking(mandate)
    end

    it "does not send out event if advertiser is not valid" do
      user.update(source_data: invalid_source_data)

      expect(Marketing::AdjustTrackingService).not_to receive(:track)
      described_class.send_adjust_demand_check_finished_tracking(mandate)
    end

    it "does not send out event when no advertiser_id is present" do
      user.update(source_data: { advertiser_ids: {} })

      expect(Marketing::AdjustTrackingService).not_to receive(:track)
      described_class.send_adjust_demand_check_finished_tracking(mandate)
    end

    it "does not die when an exception occurs in the service (but notifies Sentry)" do
      expect(Raven).to receive(:capture_exception).with(RuntimeError)

      expect(Marketing::AdjustTrackingService)
        .to receive(:track).and_raise("something went wrong")

      expect { described_class.send_adjust_demand_check_finished_tracking(mandate) }.not_to raise_error
    end

    context "young professional" do
      let(:mandate) do
        create(
          :mandate,
          state: "in_creation",
          birthdate: 26.years.ago,
          user: build(:user, source_data: { advertiser_ids: { ad_id => "gps_adid" } })
        )
      end

      let(:normal_activity) { { activity_kind: "demand_check_finished" } }
      let(:yp_activity) { { activity_kind: "demand_check_finished_young_professional" } }

      let(:tracking_attrs) do
        {
          os_name: "android",
          app_id: "de.clark",
          device_event_time: DateTime.current,
          advertiser_id: ad_id,
          mandate_id: mandate.id
        }
      end

      it "sends tracking for correct data" do
        create(:profile_datum, :yearly_gross_income, mandate: mandate, value: { text: 45_000 })

        expect(Marketing::AdjustTrackingService).to(
          receive(:track).with(tracking_attrs.merge(normal_activity))
        )
        expect(Marketing::AdjustTrackingService).to(
          receive(:track).with(tracking_attrs.merge(yp_activity))
        )

        described_class.send_adjust_demand_check_finished_tracking(mandate)
      end

      it "sends tracking for correct data with string income value" do
        create(:profile_datum, :yearly_gross_income, mandate: mandate, value: { text: "46000" })

        expect(Marketing::AdjustTrackingService).to(
          receive(:track).with(tracking_attrs.merge(normal_activity))
        )
        expect(Marketing::AdjustTrackingService).to(
          receive(:track).with(tracking_attrs.merge(yp_activity))
        )

        described_class.send_adjust_demand_check_finished_tracking(mandate)
      end

      it "does not send tracking if requirements isn't matched" do
        mandate = create(
          :mandate,
          state: "in_creation",
          birthdate: 46.years.ago,
          user: build(:user, source_data: { advertiser_ids: { ad_id => "gps_adid" } })
        )

        Timecop.freeze do
          expect(Marketing::AdjustTrackingService).to(
            receive(:track).with(tracking_attrs.merge(normal_activity).merge(mandate_id: mandate.id))
          )
          expect(Marketing::AdjustTrackingService).not_to(
            receive(:track).with(tracking_attrs.merge(yp_activity).merge(mandate_id: mandate.id))
          )

          described_class.send_adjust_demand_check_finished_tracking(mandate)
        end
      end
    end
  end

  describe "#young_professional?" do
    it "returns false if birthday is not set" do
      mandate.update(birthdate: "")

      expect(described_class.send(:young_professional?, mandate)).to eq(false)
    end
  end
end
