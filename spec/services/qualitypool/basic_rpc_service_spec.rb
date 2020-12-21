require 'rails_helper'

RSpec.describe Qualitypool::BasicRPCService do
  context '#new' do
    let(:auth_double) { double(Ripcord::Authentication::InlineToken) }
    let(:ripcord_double) { double(Ripcord::Client) }

    before :each do
      allow(Settings.qualitypool).to receive(:endpoint).and_return('http://some-server.com/rpc')
      allow(Settings.qualitypool).to receive(:api_key).and_return('some-key')
      allow(Ripcord::Client).to receive(:new).with('http://some-server.com/rpc').and_return(ripcord_double)
      allow(Ripcord::Authentication::InlineToken).to receive(:new).with('some-key').and_return(auth_double)
      allow(ripcord_double).to receive(:authentication=).with(auth_double)
    end

    it 'inits a RPC Client for the URL' do
      expect(Ripcord::Client).to receive(:new).with('http://some-server.com/rpc').and_return(ripcord_double)
      Qualitypool::BasicRPCService.new
    end

    it 'inits a RPC Client and sets authentication scheme' do
      expect(Ripcord::Authentication::InlineToken).to receive(:new).with('some-key').and_return(auth_double)
      expect(ripcord_double).to receive(:authentication=).with(auth_double)
      Qualitypool::BasicRPCService.new
    end
  end

  context 'execute remote method' do
    class TestFakeService < Qualitypool::BasicRPCService
      def execute_rpc_call(method, payload)
        super(method, payload)
      end
    end

    let(:ripcord_double) { instance_double(Ripcord::Client) }
    let(:subject) { TestFakeService.new(ripcord_double) }
    let(:fake_remote_method) { 'RemoteFakeMethod.something' }
    let(:fake_payload) { {fake: 'payload'} }
    let(:fake_error_data) { {'debug-message' => "fake error message with random seed #{rand}"} }
    let(:error_response) { rpc_response(error: {:message => 'Invalid params', :code => -12345, :data => {'debug-message' => "the debug message: \n#/from remote"}}) }
    let(:wrong_token_response) { rpc_response(error: {:message => 'Method not allowed', :code => -32000, :data => {'debug-message' => 'Method not allowed'}}) }

    it 'raises an exception, if method is not given' do
      expect {
        subject.execute_rpc_call(nil, fake_payload)
      }.to raise_error(ArgumentError, 'no remote method given')
    end

    it 'raises an exception, if method is empty' do
      expect {
        subject.execute_rpc_call('', fake_payload)
      }.to raise_error(ArgumentError, 'no remote method given')
    end

    it 'raises an exception, if the payload is missing' do
      expect {
        subject.execute_rpc_call(fake_remote_method, nil)
      }.to raise_error(ArgumentError, 'no payload given')
    end

    it 'raises an exception, if the payload is of wrong type' do
      expect {
        subject.execute_rpc_call(fake_remote_method, 'wrong payload type')
      }.to raise_error(ArgumentError, 'payload needs to be a Hash but was a String')
    end

    # TODO wrong token response -> Sentry

    it 'notifies Sentry and does nothing when the server returns an invalid response' do
      expect(ripcord_double).to receive(:call).with(fake_remote_method, Hash).and_raise(Ripcord::Error::InvalidResponse.new('<html><body><h1>403 Forbidden</h1> Request forbidden by administrative rules. </body></html>'))

      expect(Raven).to receive(:capture_exception).with(Ripcord::Error::InvalidResponse)

      subject.execute_rpc_call(fake_remote_method, fake_payload)
    end

    it 'notifies Sentry and does nothing when the server returns invalid JSON' do
      expect(ripcord_double).to receive(:call).with(fake_remote_method, Hash).and_raise(Ripcord::Error::InvalidJSON.new('{]}'))

      expect(Raven).to receive(:capture_exception).with(Ripcord::Error::InvalidJSON)

      subject.execute_rpc_call(fake_remote_method, fake_payload)
    end

    it 'returns the response' do
      expected_id = "my-id-#{rand}"
      success_response = Ripcord::JsonRPC::Response.new(JSON.parse('{}'), nil, expected_id)
      expect(ripcord_double).to receive(:call).with(fake_remote_method, Hash).and_return(success_response)

      retval = subject.execute_rpc_call(fake_remote_method, fake_payload)

      expect(retval.id).to eq(expected_id)
    end
  end

  def rpc_response(result: nil, error: nil)
    Ripcord::JsonRPC::Response.new(result, error, SecureRandom.hex(5))
  end
end
