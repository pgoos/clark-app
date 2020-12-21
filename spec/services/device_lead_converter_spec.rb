# frozen_string_literal: true

require "rails_helper"

describe DeviceLeadConverter do
  context "convert_device_lead_to_user" do
    it "converts a device_lead to a user" do
      lead = create(:device_lead, mandate: create(:mandate), campaign: "my_campaign")
      create(:device, user_id: nil, installation_id: lead.installation_id)
      user = create(:user)

      DeviceLeadConverter.convert_device_lead_to_user(lead, user)

      expect(user.mandate).to be_present
      expect(Lead.where(id: lead.id).first).to be_blank
      expect(user.devices.count).to eq(1)
      expect(user.source_data["installation_id"]).to eq(lead.installation_id)
      expect(user.source_data["from_lead"].to_s).to match("my_campaign")
    end

    it "converts a normal lead to a user" do
      lead = create(:lead, mandate: create(:mandate), campaign: "my_campaign")
      user = create(:user)

      DeviceLeadConverter.convert_device_lead_to_user(lead, user)

      expect(user.mandate).to be_present
      expect(Lead.where(id: lead.id).first).to be_blank
      expect(user.source_data["installation_id"]).to be nil
      expect(user.source_data["from_lead"].to_s).to match("my_campaign")
    end

    it "converts a device_lead to a user when mandate is complete" do
      mandate = create(:signed_unconfirmed_mandate, user: nil, lead: create(:device_lead, email: Faker::Internet.email, campaign: "my_campaign"))
      lead = mandate.lead
      create(:device, user_id: nil, installation_id: lead.installation_id)
      user = create(:user)

      DeviceLeadConverter.convert_device_lead_to_user(lead, user)

      expect(user.mandate).to be_present
      expect(Lead.where(id: lead.id).first).to be_blank
      expect(user.devices.count).to eq(1)
      expect(user.source_data["installation_id"]).to eq(lead.installation_id)
      expect(user.source_data["from_lead"].to_s).to match("my_campaign")
    end

    it "with no lead the user stays the same" do
      user = create(:user)

      DeviceLeadConverter.convert_device_lead_to_user(nil, user)

      expect(user.mandate).to be_blank
      expect(user.devices.count).to eq(0)
    end

    it "with no user the lead stays the same" do
      lead = create(:device_lead, mandate: create(:mandate))
      create(:device, user_id: nil, installation_id: lead.installation_id)

      DeviceLeadConverter.convert_device_lead_to_user(lead, nil)

      ar_lead = Lead.where(id: lead.id).first

      expect(ar_lead).to be_present
      expect(ar_lead.mandate).to be_present
    end

    it "a wrapping transaction has to fail, if the nested transaction fails" do
      # The documentation of nested transaction let us doubt, if nested AND wrapping transaction are being rolled back.
      # See: http://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#module-ActiveRecord::Transactions::ClassMethods-label-Nested+transactions
      # The testcase below should prove, that it works as expected. This is important for api v1 post 'register_or_login' to work properly.

      lead = create(:device_lead, mandate: create(:mandate))
      create(:device, user_id: nil, installation_id: lead.installation_id)
      user = create(:user)
      allow(lead).to receive(:destroy!).and_raise(RuntimeError.new("intended failure in transaction"))

      test_object_id = nil
      expect {
        ActiveRecord::Base.transaction do
          test_object_id = User.create(
            email: "test-reference@clark.de",
            password: Settings.seeds.default_password,
            password_confirmation: Settings.seeds.default_password
          ).id
          DeviceLeadConverter.convert_device_lead_to_user(lead, user)
        end
      }.to raise_error(RuntimeError)

      expect(Lead.where(id: lead.id).first).to be_present
      expect(test_object_id).to be_present
      expect(User.where(id: test_object_id).first).to be_nil
    end
  end

  context "update_user_from_device_lead" do
    it "updates a user from device_lead" do
      lead_mandate = create(:mandate)
      lead = create(:device_lead, mandate: lead_mandate)
      tracking_visit = create(:tracking_visit, mandate: lead.mandate)
      tracking_event = create(:tracking_event, mandate: lead.mandate)
      adjust_event = create(:tracking_adjust_event, mandate: lead.mandate, params: {key: "value"})
      business_event = create(:business_event, audited_mandate: lead.mandate)
      create(:device, user_id: nil, installation_id: lead.installation_id)
      user_mandate = create(:mandate)
      user = create(:user, mandate: user_mandate)

      DeviceLeadConverter.update_user_from_device_lead(lead, user)

      expect(user.mandate).to be_present
      expect(user.mandate).to eq(user_mandate)
      expect(Lead.where(id: lead.id).first).to be_blank
      expect(Mandate.where(id: lead_mandate).first).to be_blank
      expect(user.devices.count).to eq(1)
      expect(user.source_data["installation_id"]).to eq(lead.installation_id)
      expect(tracking_visit.reload.mandate).to eq(user_mandate)
      expect(tracking_event.reload.mandate).to eq(user_mandate)
      expect(adjust_event.reload.mandate).to eq(user_mandate)
      expect(business_event.reload.audited_mandate).to eq(user_mandate)
    end

    it "updates a user from normal lead" do
      lead_mandate = create(:mandate)
      lead = create(:lead, mandate: lead_mandate)
      tracking_visit = create(:tracking_visit, mandate: lead.mandate)
      tracking_event = create(:tracking_event, mandate: lead.mandate)
      adjust_event = create(:tracking_adjust_event, mandate: lead.mandate, params: {key: "value"})
      business_event = create(:business_event, audited_mandate: lead.mandate)
      user_mandate = create(:mandate)
      user = create(:user, mandate: user_mandate)

      DeviceLeadConverter.update_user_from_device_lead(lead, user)

      expect(user.mandate).to be_present
      expect(user.mandate).to eq(user_mandate)
      expect(Lead.where(id: lead.id).first).to be_blank
      expect(Mandate.where(id: lead_mandate).first).to be_blank
      expect(user.source_data["installation_id"]).to be nil
      expect(tracking_visit.reload.mandate).to eq(user_mandate)
      expect(tracking_event.reload.mandate).to eq(user_mandate)
      expect(adjust_event.reload.mandate).to eq(user_mandate)
      expect(business_event.reload.audited_mandate).to eq(user_mandate)
    end

    it "with no lead the user stays the same" do
      user_mandate = create(:mandate)
      user = create(:user, mandate: user_mandate)

      DeviceLeadConverter.update_user_from_device_lead(nil, user)

      expect(user.mandate).to eq(user_mandate)
      expect(user.devices.count).to eq(0)
    end

    it "with no user the lead stays the same" do
      lead_mandate = create(:mandate)
      lead = create(:device_lead, mandate: lead_mandate)
      create(:device, user_id: nil, installation_id: lead.installation_id)

      DeviceLeadConverter.update_user_from_device_lead(lead, nil)

      ar_lead = Lead.where(id: lead.id).first

      expect(ar_lead).to be_present
      expect(ar_lead.mandate).to be_present
    end

    it "also works when the mandate has inquiries" do
      lead_mandate = create(:mandate)
      lead_mandate.inquiries << create(:inquiry)
      lead = create(:device_lead, mandate: lead_mandate)
      device = create(:device, user_id: nil, installation_id: lead.installation_id)
      user = create(:user, mandate: create(:mandate))

      expect {
        DeviceLeadConverter.update_user_from_device_lead(lead, user)
      }.to change(Lead, :count).by(-1).and change(Mandate, :count).by(-1).and change(Inquiry, :count).by(-1)

      user.mandate.reload
      user.reload

      expect(user.devices.first).to eq(device)
      expect(user.source_data["installation_id"]).to eq(lead.installation_id)
    end
  end
end
