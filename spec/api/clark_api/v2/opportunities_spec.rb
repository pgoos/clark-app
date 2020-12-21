# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Opportunities, :integration do
  let(:cockpit) { create(:retirement_cockpit) }
  let(:mandate)  { create(:mandate, retirement_cockpit: cockpit) }
  let(:user)     { create(:user, mandate: mandate) }
  let(:product)  { create(:product) }
  let(:category) { product.category }
  let(:metadata) { {"originated_from" => "retirement_overview"} }
  let!(:advice)  { create(:advice, topic: product, admin: advice_admin, mandate: mandate) }
  let!(:advice_admin) { create(:advice_admin) }
  let(:appointment) { create(:appointment, appointable: cockpit) }

  context "when mandate is invalid" do
    it "does't validate mandate" do
      mandate2 = create(:mandate)
      user2 = create(:user, mandate: mandate2)
      advice2 = create(:advice, topic: product, admin: advice_admin, mandate: mandate2)
      login_as(user2, scope: :user)
      mandate2.addresses = []
      mandate2.current_wizard_step = :profiling
      mandate2.active_address.destroy
      params = {
        category_ident: category.ident,
        source_type: Interaction::Advice.name,
        source_id: advice2.id,
        metadata: metadata
      }
      mandate2 = mandate2.reload
      expect(mandate2).not_to be_valid
      json_post_v2 "/api/opportunities", params
      expect(response.status).to eq 201
    end
  end

  context "when valid user" do
    let(:created_opportunity) { Opportunity.find(json_response.opportunity.id) }

    before do
      login_as(user, scope: :user)
      json_post_v2 "/api/opportunities", params
    end

    context "with basic attributes" do
      let(:sales_campaign) { create(:sales_campaign) }
      let(:params) do
        {
          category_ident: category.ident,
          source_type: Interaction::Advice.name,
          source_id: advice.id,
          metadata: metadata,
          source_description: "Pre-Sales: Outbound Call",
          sales_campaign_id: sales_campaign.id
        }
      end

      it { expect(response).to be_created }
      it { expect(created_opportunity.mandate).to eq(mandate) }
      it { expect(created_opportunity.category).to eq(category) }
      it { expect(created_opportunity.source).to eq(advice) }
      it { expect(created_opportunity).to be_created }
      it { expect(created_opportunity.metadata).to eq(metadata) }
      it { expect(created_opportunity.source_description).to eq("Pre-Sales: Outbound Call") }
      it { expect(created_opportunity.sales_campaign).to eq(sales_campaign) }
    end

    context "with appointment source" do
      let(:sales_campaign) { create(:sales_campaign) }
      let(:params) do
        {
          category_ident: category.ident,
          source_type: Appointment.name,
          source_id: appointment.id,
          metadata: metadata
        }
      end

      it { expect(created_opportunity.source).to eq(appointment) }
      it { expect(appointment.reload.appointable).to eq(created_opportunity) }
    end

    context "with state" do
      let(:params) do
        {
          category_ident: category.ident,
          source_type: Interaction::Advice.name,
          source_id: advice.id,
          state: :initiation_phase
        }
      end

      it { expect(created_opportunity).to be_initiation_phase }
    end

    context "with old_product" do
      let(:params) do
        {
          category_ident: category.ident,
          source_type: Interaction::Advice.name,
          source_id: advice.id,
          old_product_id: product.id
        }
      end

      it { expect(created_opportunity.old_product).to eq(product) }
    end

    context "with recommendation" do
      let(:recommendation) { create(:recommendation) }
      let(:params) do
        {
          category_ident: category.ident,
          source_type: Recommendation.name,
          source_id: recommendation.id
        }
      end

      it { expect(created_opportunity.source).to eq(recommendation) }
    end
  end

  context "when invalid user" do
    let(:params) do
      {
        category_ident: category.ident,
        source_type: Interaction::Advice.name,
        source_id: advice.id
      }
    end

    it "returns unauthorized" do
      json_post_v2 "/api/opportunities", params
      expect(response).to be_unauthorized
    end
  end

  context "when invalid params" do
    let(:params) do
      {
        category_ident: category.ident,
        source_type: Interaction::Advice.name,
        source_id: advice.id
      }
    end

    before do
      login_as(user, scope: :user)
      json_post_v2 "/api/opportunities", params
    end

    it_behaves_like "an authenticated api request", "/api/opportunities"

    context "with invalid source_type" do
      let(:params) do
        {
          category_ident: category.ident,
          source_type: "nonsense",
          source_id: advice.id
        }
      end

      it { expect(response).to be_bad_request }
    end

    context "with missing source_type" do
      let(:params) do
        {
          category_ident: category.ident,
          source_id: advice.id
        }
      end

      it { expect(response).to be_bad_request }
    end

    context "with invalid category_ident" do
      let(:params) do
        {
          category_ident: "123 456",
          source_type: "nonsense",
          source_id: advice.id
        }
      end

      it { expect(response).to be_bad_request }
    end

    context "with missing category_ident" do
      let(:params) do
        {
          source_type: "nonsense",
          source_id: advice.id
        }
      end

      it { expect(response).to be_bad_request }
    end
  end
end
