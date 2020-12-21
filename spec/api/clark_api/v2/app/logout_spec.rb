require 'rails_helper'
require 'support/api_schema_matcher'
require 'ostruct'

include ApiSchemaMatcher

RSpec.describe ClarkAPI::V2::App::Logout, :integration do
  context 'POST /api/app/logout' do
    it 'logs the user out' do
      login_as(create(:user, mandate: create(:mandate)), :scope => :user)

      json_post_v2 '/api/app/logout'

      expect(response.status).to eq(200)
      expect(json_response.success).to eq(true)
      expect(@integration_session.request.env['warden'].user(:user)).to be_nil
    end

    it 'does not throw an error if the user was not signed in' do
      json_post_v2 '/api/app/logout'

      expect(response.status).to eq(200)
      expect(json_response.success).to eq(true)
      expect(@integration_session.request.env['warden'].user(:user)).to be_nil
    end

    it 'logs the user out' do
      login_as(create(:device_lead, mandate: create(:mandate)), :scope => :lead)

      json_post_v2 '/api/app/logout'

      expect(response.status).to eq(200)
      expect(json_response.success).to eq(true)
      expect(@integration_session.request.env['warden'].user(:lead)).to be_nil
    end
  end
end
