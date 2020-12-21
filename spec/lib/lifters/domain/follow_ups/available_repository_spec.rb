# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::FollowUps::AvailableRepository do
  describe ".call" do
    let(:admin) { create(:admin) }
    let(:mandate) { create(:mandate) }
    let(:revoked_mandate) { create(:mandate, :revoked) }

    context "without filter params" do
      let(:current_time) { Time.current }
      let!(:follow_up) { create(:follow_up, :skip_validation, item: mandate, due_date: Time.current) }
      let!(:follow_up_30_days_old) do
        create(:follow_up, :skip_validation, item: mandate, due_date: current_time - 30.day)
      end
      let!(:follow_up_31_days_old) do
        create(:follow_up, :skip_validation, item: mandate, due_date: current_time - 31.day)
      end

      it "should fetch all follow_ups that are not more than 30 days old" do
        expect(
          described_class.call(current_admin_id: admin.id).map(&:id)
        ).to match_array([follow_up.id, follow_up_30_days_old.id])
      end
    end

    context "with by_acknowledged filter" do
      let!(:unacknowledged_follow_up) { create(:follow_up, :unacknowledged, item: mandate) }
      let!(:acknowledged_follow_up) { create(:follow_up, :acknowledged, item: mandate) }

      it "should only fetch unacknowledged follow_ups if by_acknowledged filter is false" do
        params = { "by_acknowledged" => "false", current_admin_id: admin.id }
        expect(
          described_class.call(params).map(&:id)
        ).to eq([unacknowledged_follow_up.id])
      end

      it "should only fetch acknowledged follow_ups if by_acknowledged filter is true" do
        params = { "by_acknowledged" => "true", current_admin_id: admin.id }
        expect(
          described_class.call(params).map(&:id)
        ).to eq([acknowledged_follow_up.id])
      end
    end

    context "with by_admin_id filter" do
      let!(:follow_up1) { create(:follow_up, admin: admin, item: mandate) }
      let!(:follow_up2) { create(:follow_up, item: mandate) }

      it "should only fetch follow_ups that assigned to that admin" do
        params = { "by_admin_id" => admin.id, current_admin_id: admin.id }
        expect(described_class.call(params).map(&:id)).to eq([follow_up1.id])
      end
    end

    context "with by_interaction_type filter" do
      let(:admin) { create(:admin) }
      let!(:follow_up1) { create(:follow_up, :phone_call, item: mandate) }
      let!(:follow_up2) { create(:follow_up, :message, item: mandate) }

      it "should fetch only phone_call follow_ups when interaction_type is phone_call" do
        params = { "by_interaction_type" => "phone_call", current_admin_id: admin.id }
        expect(described_class.call(params).map(&:id)).to eq([follow_up1.id])
      end

      it "should fetch message follow_ups for message interaction_type filter" do
        params = { "by_interaction_type" => "message", current_admin_id: admin.id }
        expect(described_class.call(params).map(&:id)).to eq([follow_up2.id])
      end
    end

    context "when Followup is created for revoked mandate" do
      let!(:followup_with_active_mandate) do
        create(:follow_up, item: mandate, due_date: Time.current + 1.day)
      end
      let!(:followup_with_revoked_mandate) do
        create(:follow_up, item: revoked_mandate, due_date: Time.current + 1.day)
      end

      context "when admin have neccessary permission to see revoked mandates" do
        before do
          admin.permissions << create(:permission, :view_revoked_mandates)
        end

        it "shows revoked follow_up" do
          expect(
            described_class.call(current_admin_id: admin.id).map(&:id)
          ).to eq([followup_with_active_mandate.id, followup_with_revoked_mandate.id])
        end
      end

      context "when admin does not have permission to see revoked mandates" do
        it "does not show revoked follow_up" do
          expect(
            described_class.call(current_admin_id: admin.id).map(&:id)
          ).to eq([followup_with_active_mandate.id])
        end
      end
    end

    context "when Followup is created for product belonging to revoked mandate" do
      let(:product_with_active_mandate) { create(:product, mandate: mandate) }
      let(:product_with_revoked_mandate) { create(:product, mandate: revoked_mandate) }
      let!(:followup_with_active_mandate) do
        create(:follow_up, item: product_with_active_mandate, due_date: Time.current + 1.day)
      end
      let!(:followup_with_revoked_mandate) do
        create(:follow_up, item: product_with_revoked_mandate, due_date: Time.current + 1.day)
      end

      context "when admin have neccessary permission to see revoked mandates" do
        before do
          admin.permissions << create(:permission, :view_revoked_mandates)
        end

        it "shows revoked follow_up" do
          expect(
            described_class.call(current_admin_id: admin.id).map(&:id)
          ).to eq([followup_with_active_mandate.id, followup_with_revoked_mandate.id])
        end
      end

      context "when admin does not have permission to see revoked mandates" do
        it "does not show revoked follow_up" do
          expect(
            described_class.call(current_admin_id: admin.id).map(&:id)
          ).to eq([followup_with_active_mandate.id])
        end
      end
    end

    context "when Followup is created for inquiry belonging to revoked mandate" do
      let(:inquiry_with_active_mandate) { create(:inquiry, mandate: mandate) }
      let(:inquiry_with_revoked_mandate) { create(:inquiry, mandate: revoked_mandate) }
      let!(:followup_with_active_mandate) do
        create(:follow_up, item: inquiry_with_active_mandate, due_date: Time.current + 1.day)
      end
      let!(:followup_with_revoked_mandate) do
        create(:follow_up, item: inquiry_with_revoked_mandate, due_date: Time.current + 1.day)
      end

      context "when admin have neccessary permission to see revoked mandates" do
        before do
          admin.permissions << create(:permission, :view_revoked_mandates)
        end

        it "shows revoked follow_up" do
          expect(
            described_class.call(current_admin_id: admin.id).map(&:id)
          ).to eq([followup_with_active_mandate.id, followup_with_revoked_mandate.id])
        end
      end

      context "when admin does not have permission to see revoked mandates" do
        it "does not show revoked follow_up" do
          expect(
            described_class.call(current_admin_id: admin.id).map(&:id)
          ).to eq([followup_with_active_mandate.id])
        end
      end
    end

    context "when Followup is created for opportunity belonging to revoked mandate" do
      let(:opportunity_with_active_mandate) { create(:opportunity, mandate: mandate) }
      let(:opportunity_with_revoked_mandate) do
        create(:opportunity, :skip_validations, mandate: revoked_mandate)
      end
      let!(:followup_with_active_mandate) do
        create(:follow_up, item: opportunity_with_active_mandate, due_date: Time.current + 1.day)
      end
      let!(:followup_with_revoked_mandate) do
        create(:follow_up, item: opportunity_with_revoked_mandate, due_date: Time.current + 1.day)
      end

      context "when admin have neccessary permission to see revoked mandates" do
        before do
          admin.permissions << create(:permission, :view_revoked_mandates)
        end

        it "shows revoked follow_up" do
          expect(
            described_class.call(current_admin_id: admin.id).map(&:id)
          ).to eq([followup_with_active_mandate.id, followup_with_revoked_mandate.id])
        end
      end

      context "when admin does not have permission to see revoked mandates" do
        it "does not show revoked follow_up" do
          expect(
            described_class.call(current_admin_id: admin.id).map(&:id)
          ).to eq([followup_with_active_mandate.id])
        end
      end
    end
  end
end
