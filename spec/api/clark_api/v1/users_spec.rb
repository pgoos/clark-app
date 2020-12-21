require 'rails_helper'

RSpec.describe ClarkAPI::V1::Users, :slow, :integration do
  context 'GET /users/me' do
    it 'returns a 404 error when noone is logged in' do
      json_get '/api/users/me'
      expect(response.status).to eq(404)
      expect(json_response.error).to eq('not signed in')
    end

    it 'returns user data with mandate if user is logged in' do
      user = create(:user, mandate: create(:mandate))
      login_as(user, :scope => :user)

      json_get '/api/users/me'
      expect(response.status).to eq(200)
      expect(json_response.user.email).to eq(user.email)
      expect(json_response.user.id).to eq(user.id)
      expect(json_response.user.mandate.first_name).to eq(user.mandate.first_name)
      expect(json_response.user.keys).to match_array(%w(id email mandate))
    end
  end
end
