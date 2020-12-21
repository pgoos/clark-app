require 'rails_helper'

RSpec.describe ClarkAPI::V2::Invitations, :integration do

  context 'POST /api/invitations' do
    it 'sends email with a invitation' do
      user = create(:user, mandate: create(:mandate))
      login_as(user, :scope => :user)

      expect {
        json_post_v2 '/api/invitations', {email: 'abc@abc.de'}
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response.status).to eq(201)
    end

    it 'missing email does not send an email' do
      user = create(:user, mandate: create(:mandate))
      login_as(user, :scope => :user)

      expect {
        json_post_v2 '/api/invitations'
      }.to change { ActionMailer::Base.deliveries.count }.by(0)

      expect(response.status).to eq(400)
    end

    it 'returns 401 if the user is not singed in' do
      json_post_v2 '/api/invitations', {email: 'abc@abc.de'}
      expect(response.status).to eq(401)
    end
  end
end

