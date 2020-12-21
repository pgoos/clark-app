require 'rails_helper'

describe InboundChannels::Messenger::Token do
  describe ".issue" do
    subject { InboundChannels::Messenger::Token.issue(mandate) }
    let!(:mandate) { create :mandate }

    before do
      allow(Features).to receive(:active?).with(Features::MESSENGER).and_return(true)
    end

    it 'returns a JWT with mandate_id in playload' do
      decoded_token = JWT.decode subject, Settings.messenger.token_secret, true, { algorithm: 'HS256' }
      expect(decoded_token[0]["mandate_id"]).to eq(mandate.id)
    end

    it "doesn't return a token if the feature switch is off" do
      allow(Features).to receive(:active?).with(Features::MESSENGER).and_return(false)
      expect(subject).to be_nil
    end
  end
end
