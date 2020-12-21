# frozen_string_literal: true

require "rails_helper"

RSpec.describe "admin/mandates/_mandate_brief.html.haml", :integration do
  let(:mandate) do
    create(
      :mandate,
      :accepted,
      addresses: [create(:address, :active, :accepted, active_at: Time.zone.now - 2.days)],
      user: create(:user)
    )
  end

  before do
    view.lookup_context.prefixes << "admin/base"
    allow(view).to receive(:url_options).and_return(locale: :de)
    allow(view).to receive(:current_namespace).and_return(:admin)
    allow(view).to receive(:resource).and_return(mandate)
    allow(view).to receive(:customer_badge).with(mandate)
  end

  after do
    allow(view).to receive(:url_options).and_call_original
    allow(view).to receive(:current_namespace).and_call_original
    allow(view).to receive(:resource).and_call_original
    allow(view).to receive(:admin_mandates_path).and_call_original
    allow(view).to receive(:admin_mandate_path).and_call_original
  end

  it "renders the template" do
    expect(view).not_to receive(:admin_mandates_path).with(mandate)
    expect(view).to receive(:admin_mandate_path).with(mandate).and_call_original

    render "admin/mandates/mandate_brief",
           mandate: mandate,
           active_address: mandate.active_address,
           params: {locale: :de}

    expect(rendered).to match(/data-mandate-brief/)
  end

  context "when multiple addresses is active" do
    let(:now) { Time.zone.now }
    let(:future) { now + 2.days }

    before do
      # Timecop is not used here, since the underlying query uses the db to select the next active address.
      create(:feature_switch, key: Features::MULTIPLE_ADDRESSES, active: true)
    end

    after do
      FeatureSwitch.find_by_key(Features::MULTIPLE_ADDRESSES).destroy!
    end

    it "renders the template with the next active address included" do
      new_address = attributes_for(:address, :accepted, active_at: future, street: "New Street", active: false)
      mandate.addresses.create(new_address)
      render "admin/mandates/mandate_brief",
             mandate: mandate,
             active_address: mandate.active_address,
             next_active_address: mandate.next_active_address,
             params: {locale: :de}
      expect(rendered).to match(/New Street/)
    end
  end
end
