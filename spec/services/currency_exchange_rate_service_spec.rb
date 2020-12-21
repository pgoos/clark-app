require 'rails_helper'

RSpec.describe CurrencyExchangeRateService, :fail do

  describe CurrencyExchangeRateService::CurrencylayerRemoteService, :regression do

    # These tests are excluded by default. See the file <RAILS_ROOT>/.rspec
    # In order to execute these tests, please run
    # bin/rspec --tag regression spec/services/currency_exchange_rate_service_spec.rb

    it 'should have an access key configured' do
      skip
      expect(Settings.currencylayer.api_key).to_not be(nil)
    end

    it 'should call the remote api successfully' do
      skip
      parsed_response = CurrencyExchangeRateService::CurrencylayerRemoteService.new.historical_exchange_rates(Date.new(2016, 02, 13))
      expect(parsed_response['success']).to be(true)
      expect(parsed_response['historical']).to be(true)
      expect(parsed_response['quotes']['USDEUR']).to be_within(0.01).of(0.88)
    end

  end

  context 'remote service http error handling' do
    let(:fake_response) { double(message: 'fake message', response_body_permitted?: true, body: '{"fake body" : "fake value"}', code: '200') }
    let(:remote_service) { CurrencyExchangeRateService::CurrencylayerRemoteService.new }

    before do
      allow(Net::HTTP).to receive(:start) { fake_response }
    end

    it 'should raise, if the request did not succeed for client reasons' do
      allow(fake_response).to receive(:code) { '400' }
      expect {
        remote_service.historical_exchange_rates(Date.new(2016, 02, 13))
      }.to raise_error("Http request failed! Response code: '#{fake_response.code}', response message: '#{fake_response.message}', response body: '#{fake_response.body}'")
    end

    it 'should raise, if the request did not succeed for server reasons' do
      allow(fake_response).to receive(:code) { '500' }
      expect {
        remote_service.historical_exchange_rates(Date.new(2016, 02, 13))
      }.to raise_error("Http request failed! Response code: '#{fake_response.code}', response message: '#{fake_response.message}', response body: '#{fake_response.body}'")
    end

    it 'should succeed, if the request returned a status code 200' do
      allow(fake_response).to receive(:code) { '200' }
      expect {
        remote_service.historical_exchange_rates(Date.new(2016, 02, 13))
      }.to_not raise_error
    end

    it 'should succeed, if the request returned a status code 304' do
      allow(fake_response).to receive(:code) { '304' }
      expect {
        remote_service.historical_exchange_rates(Date.new(2016, 02, 13))
      }.to_not raise_error
    end
  end

  context 'erroneous calls from the client side' do
    it 'should validate, there is a date' do
      expect {
        CurrencyExchangeRateService.historical_exchange_rates(nil)
      }.to raise_error('Date is missing!')
    end

    it 'should validate, a date is not in the future' do
      expect {
        CurrencyExchangeRateService.historical_exchange_rates(Date.tomorrow)
      }.to raise_error('Date is in the future! Requesting historical currency data requires the date to be in the past!')
    end

    it 'should validate that dollars are given as number' do
      expect {
        CurrencyExchangeRateService.us_dollars_to_eur(nil, Date.yesterday)
      }.to raise_error('The money value need to be an instance of Numeric!')
    end
  end

  context 'erroneous return values from remote' do
    let(:expected_response) {
      {
        'success' => false,
        'error' => {
          'code' => 104,
          'info' => 'User has reached or exceeded his subscription plan\'s monthly API request allowance.'
        }
      }
    }

    before do
      expect_any_instance_of(CurrencyExchangeRateService::CurrencylayerFakeService).to receive(:historical_exchange_rates).with(Date.yesterday) { expected_response }
    end

    it 'should raise an error, if the call to remote was not successful for historical data' do
      expect {
        CurrencyExchangeRateService.historical_exchange_rates(Date.yesterday)
      }.to raise_error("Remote error! Code: '#{expected_response['error']['code']}', Message: '#{expected_response['error']['info']}'")
    end
  end

  context 'successful calls' do
    it 'should convert 1 US $ into EUR' do
      expect(CurrencyExchangeRateService.us_dollars_to_eur(1, Date.yesterday)).to be_within(0.01).of(0.85)
    end

    it 'should convert 5 US $ into EUR' do
      expect(CurrencyExchangeRateService.us_dollars_to_eur(5, Date.yesterday)).to be_within(0.01).of(0.85 * 5)
    end
  end
end
