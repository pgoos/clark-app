require 'rails_helper'
require 'lifters/outbound_channels/mocks/fake_remote_sns_client'

describe OutboundChannels::PhoneCall do
  let (:admin) { create(:admin, sip_uid: 'sip@example.de') }
  let(:processable_phone_number) { '012345678900' }

  before do
    Settings.placetel.sandbox_mode = false
  end

  after do
    Settings.reload!
  end

  describe '#initiate_call' do
    it 'initiates a call to a phone number' do
      expect{described_class.new.initiate_call(processable_phone_number, admin)}.not_to raise_error
    end

    it 'raises argument error if unprocessable german phone number is passed' do
      unprocessable_phone_number = '911'
      subject = described_class.new
      expect do
        subject.initiate_call(unprocessable_phone_number, admin)
      end.to raise_error(ArgumentError)
    end

    it 'raises argument error if an admin without sip uid was passed' do
      admin.sip_uid = nil
      subject = described_class.new
      expect do
        subject.initiate_call(processable_phone_number, admin)
      end.to raise_error(ArgumentError)
    end
  end
end
