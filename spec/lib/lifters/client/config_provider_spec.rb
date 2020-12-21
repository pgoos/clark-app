# frozen_string_literal: true

require "rails_helper"

describe Domain::Client::ConfigProvider do
  it { is_expected.to respond_to :first_information_pdf }
  it { is_expected.to respond_to :terms_pdf }
  it { is_expected.to respond_to :privacy_pdf }
  it { is_expected.to respond_to :insurer_privacy_pdf }
  it { is_expected.to respond_to :retirement_calculation_pdf }
  it { is_expected.to respond_to :agb_link }
  it { is_expected.to respond_to :datenschutz_link }
  it { is_expected.to respond_to :datenschutz_pools_link }
  it { is_expected.to respond_to :erstinformation_link }
  it { is_expected.to respond_to :clark2 }

  describe "#clark2" do
    it "retrieves a value from the settings" do
      expect(Settings).to receive_message_chain(:app_features, :clark2)
      subject
    end
  end
end
