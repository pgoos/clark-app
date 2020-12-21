# frozen_string_literal: true

require "rails_helper"

RSpec.describe "admin/opportunities/_show.html.haml", :integration do
  let(:resource) do
    create(
      :opportunity,
      mandate: create(
        :mandate,
        :accepted,
        addresses: [
          create(:address, :active, :accepted, active_at: Time.zone.now - 1.year),
          create(:address, :accepted, active_at: Time.zone.now + 1.week, active: false)
        ],
        user: create(:user)
      )
    )
  end

  before do
    allow_any_instance_of(Admin::BaseHelper).to receive(:admin_signed_in?).and_return(true)
    allow_any_instance_of(Admin::BaseHelper).to receive(:current_admin).and_return(double("admin", permitted_to?: true))

    view.lookup_context.prefixes << "admin/base"
    view.extend Admin::BaseHelper
    view.extend Comfy::CmsHelper
    view.extend SortHelper

    view.instance_variable_set(:@opportunity, resource.decorate)

    allow(view).to receive(:resource).and_return(resource)
    allow(view).to receive(:resource_class).and_return(Opportunity)
    allow(view).to receive(:url_options).and_return(locale: :de)
  end

  after do
    allow(view).to receive(:resource).and_call_original
    allow(view).to receive(:resource_class).and_call_original
    allow(view).to receive(:url_options).and_call_original
  end

  it "renders the template" do
    render "admin/opportunities/show"
    expect(rendered).to match(/<td>Quelle/)
  end
end
