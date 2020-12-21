# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::ErrorHandlers::Generic do
  let(:rails_env) { double(:rails_env, production?: false, test?: true, development?: false) }

  let(:name) { "Exception Name" }
  let(:klass) { double(:class, name: name) }
  let(:message) { "Exception message" }
  let(:backtrace) { ["Backtrace", "line 1", "line 2"] }
  let(:exception) do
    double(:exception, class: klass, message: message, backtrace: backtrace)
  end

  let(:request_method) { "GET" }
  let(:http_accept) { "application/vnd.clark-v5+json" }
  let(:request_env) { {"REQUEST_METHOD" => request_method, "HTTP_ACCEPT" => http_accept} }

  let(:handler) { described_class.new(rails_env) }

  describe ".handler" do
    subject { described_class.handler }

    before do
      allow(described_class).to receive(:env).and_return(request_env)
      allow(described_class).to receive(:current_mandate).and_return(nil)
    end

    it do
      expect(described_class).to receive(:new).and_return(handler)
      expect(handler).to receive(:log_exception)
        .with(exception, request_env, nil)
        .and_call_original
      expect(described_class).to receive(:error!)
        .with({errors: handler.error_content(exception)}, handler.status(exception))

      subject.call(exception)
    end
  end

  describe "#status" do
    context "exception without status" do
      it { expect(handler.status(exception)).to be(500) }
    end

    context "exception with nil status" do
      let(:exception) { double(:exception, status: nil) }

      it { expect(handler.status(exception)).to be(500) }
    end

    context "exception with defined status" do
      let(:status) { 123 }
      let(:exception) { double(:exception, status: status) }

      it { expect(handler.status(exception)).to be(status) }
    end
  end

  describe "#error_content" do
    context "other than production environment" do
      subject { handler.error_content(exception)[name] }

      let(:rails_env) { double(:rails_env, production?: false) }

      it do
        expect(subject[:message]).to eql(message)
        expect(subject[:stacktrace]).to eql(backtrace)
      end
    end

    context "production environment" do
      subject { handler.error_content(exception) }

      let(:rails_env) { double(:rails_env, production?: true) }

      it { expect(subject).to be(described_class::SERVER_ERROR_MSG) }
    end
  end

  describe "#log_exception" do
    context "development environment" do
      let(:rails_env) { double(:rails_env, test?: false, development?: true, production?: false) }

      it do
        expect(Rails.logger).to receive(:error).with(exception.message)
        expect(Rails.logger).to receive(:error).with(exception.backtrace.join("\n"))

        handler.log_exception(exception, request_env)
      end
    end

    context "test environment" do
      subject { handler.error_content(exception)[name] }

      let(:rails_env) { double(:rails_env, test?: true, development?: false, production?: false) }

      it do
        expect(subject[:message]).to eql(message)
        expect(subject[:stacktrace]).to eql(backtrace)
      end
    end

    context "production environment" do
      let(:rails_env) { double(:rails_env, test?: false, development?: false, production?: true) }
      let(:id) { 123 }
      let(:current_mandate) { double(:current_mandate, id: id, customer_state: :prospect) }

      context "with everything" do
        let(:handler) { described_class.new(rails_env) }

        it do
          expect(Rails.logger).to receive(:error).with(exception.message)
          expect(Raven).to receive(:capture_exception).with(exception)
          expect(Raven).to receive(:extra_context).with(mandate_id: id, api_version: http_accept)
          expect(Raven).to receive(:tags_context).with(method: request_method)

          handler.log_exception(exception, request_env, current_mandate)
        end
      end

      context "without current mandate" do
        let(:handler) { described_class.new(rails_env) }

        it do
          expect(Rails.logger).to receive(:error).with(exception.message)
          expect(Raven).to receive(:capture_exception).with(exception)
          expect(Raven).not_to receive(:extra_context).with(mandate_id: id)
          expect(Raven).to receive(:tags_context).with(method: request_method)

          handler.log_exception(exception, request_env)
        end
      end
    end
  end
end
