# frozen_string_literal: true

require "rails_helper"
require "composites/customer/interactors/client_launcher_variant"

# Needed to test rand method
# rubocop:disable RSpec/SubjectStub
RSpec.describe Customer::Interactors::ClientLauncherVariant do
  subject { described_class.new(clark2_configuration: clark2_configuration) }

  let(:clark2_configuration) do
    double(:config,
           ios_probability_value: 50,
           android_probability_value: 60,
           other_probability_value: 70)
  end

  let(:non_eligible_utm_sources) { %w[FOO BAR] }
  let(:eligible_utm_sources) { %w[BAZ] }

  let(:clark2_user_agent) { "Mozilla/5.0 ... (Device: x86_64 iOS: 13.4.1) Clark/0.1.1 Firestarter/0.1.0" }
  let(:clark1_user_agent) { "Mozilla/5.0 ... (Device: x86_64 iOS: 13.4.1) Clark/0.1.1 " }
  let(:other_user_agent) { "Mozilla/5.0 ... (Device: x86_64 iOS: 13.4.1)" }

  let(:variant1) { "1" }
  let(:variant2) { "2" }

  let(:clark1_customer) { double(:customer, id: 1, customer_state: nil) }
  let(:clark2_customer) { double(:customer, id: 2, customer_state: "prospect") }

  before do
    allow(Settings).to receive_message_chain(:launcher, :clark2, :non_eligible_ad_network) { non_eligible_utm_sources }
  end

  context "with customer" do
    context "when customer is clark2" do
      it "returns variant 2" do
        result = subject.(customer: clark2_customer)
        expect(result.variant).to eq variant2
        expect(result.chosen_randomly).to eq false
      end
    end

    context "when customer is clark1" do
      it "returns variant 1" do
        result = subject.(customer: clark1_customer)
        expect(result.variant).to eq variant1
        expect(result.chosen_randomly).to eq false
      end
    end
  end

  context "with user_agent" do
    it "returns variant 1 if client doesn't support clark2" do
      result = subject.(user_agent: clark1_user_agent)
      expect(result.variant).to eq variant1
    end

    it "proceeds to the net checks if client is not clark app" do
      result = subject.(user_agent: other_user_agent)
      expect(result.chosen_randomly).to eq true
    end

    it "proceeds to the next checks if client supports clark2" do
      result = subject.(user_agent: clark2_user_agent, has_adjust_data: true)
      expect(result.chosen_randomly).to eq true

      agent = "Mozilla/5.0 ... (Device: x86_64 iOS: 13.4.1) firestarter/1.2.5"
      result = subject.(user_agent: agent)
      expect(result.chosen_randomly).to eq true
    end
  end

  context "with override_variant param" do
    it "parses param and returns result" do
      result = subject.(override_variant: variant1)
      expect(result.variant).to eq variant1

      result = subject.(override_variant: variant2)
      expect(result.variant).to eq variant2

      expect(result.chosen_randomly).to eq false
    end
  end

  context "with local_storage_variant param" do
    it "parses param and returns result" do
      result = subject.(local_storage_variant: variant1)
      expect(result.variant).to eq variant1

      result = subject.(local_storage_variant: variant2)
      expect(result.variant).to eq variant2

      expect(result.chosen_randomly).to eq false
    end
  end

  context "with utm_source" do
    context "when utm_source parameter is passed" do
      it "returns clark1 when utm_source is not eligible for clark2" do
        result = subject.(utm_source: non_eligible_utm_sources[0])
        expect(result.variant).to eq variant1
        expect(result.chosen_randomly).to eq false
      end

      it "returns random choice when utm_source is eligible" do
        expect(subject).to receive(:rand).with(1..100).and_return 50
        result = subject.(utm_source: eligible_utm_sources[0])
        expect(result.chosen_randomly).to eq true
      end
    end
  end

  context "with memorized variant" do
    it "parses param and returns result" do
      result = subject.(memorized_variant: variant1)
      expect(result.variant).to eq variant1

      result = subject.(memorized_variant: variant2)
      expect(result.variant).to eq variant2

      expect(result.chosen_randomly).to eq false
    end
  end

  context "when has_adjust_data is false" do
    context "when client is app" do
      it "returns clark1" do
        result = subject.(has_adjust_data: false, user_agent: clark2_user_agent)
        expect(result.variant).to eq variant1
      end
    end

    context "when client is not app" do
      it "proceeds the checks futher" do
        result = subject.(has_adjust_data: false, user_agent: other_user_agent)
        expect(result.chosen_randomly).to eq true
      end
    end
  end

  context "when has_adjust_data is true" do
    it "proceeds the checks futher" do
      result = subject.(has_adjust_data: true, user_agent: clark2_user_agent)
      expect(result.chosen_randomly).to eq true
    end
  end

  context "when no parameters matched" do
    context "when device platform is ios" do
      it "returns random choice" do
        user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 13_4_1 like Mac OS X) " \
                     "AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 | " \
                     "Clark/2.2.2(Build: 0000.0000.1) (Device: x86_64 iOS: 13.4.1) " \
                     "Firestarter/0.1.0"

        expect(subject).to receive(:rand).with(1..100).and_return 50
        result = subject.(user_agent: user_agent, has_adjust_data: true)
        expect(result.variant).to eq variant2

        expect(subject).to receive(:rand).with(1..100).and_return 51
        result = subject.(user_agent: user_agent, has_adjust_data: true)
        expect(result.variant).to eq variant1

        expect(result.chosen_randomly).to eq true
      end
    end

    context "when device platform is android" do
      it "returns random choice" do
        user_agent = "Mozilla/5.0 (Linux; Android 10; Pixel 4 Build/QQ2A.200405.005; " \
                     "wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 " \
                     "Chrome/81.0.4044.117 Mobile Safari/537.36 Clark/3.4.0-master " \
                     "Firestarter/0.1.0"

        expect(subject).to receive(:rand).with(1..100).and_return 60
        result = subject.(user_agent: user_agent, has_adjust_data: true)
        expect(result.variant).to eq variant2

        expect(subject).to receive(:rand).with(1..100).and_return 61
        result = subject.(user_agent: user_agent, has_adjust_data: true)
        expect(result.variant).to eq variant1

        expect(result.chosen_randomly).to eq true
      end
    end

    context "when device plafrom is neither ios nor android" do
      it "returns random choice" do
        user_agent = Faker::Internet.user_agent

        expect(subject).to receive(:rand).with(1..100).and_return 70
        result = subject.(user_agent: user_agent)
        expect(result.variant).to eq variant2

        expect(subject).to receive(:rand).with(1..100).and_return 71
        result = subject.(user_agent: user_agent)
        expect(result.variant).to eq variant1

        expect(result.chosen_randomly).to eq true
      end
    end
  end

  context "with multiple parameters" do
    let(:params) do
      {
        customer: clark1_customer,
        user_agent: clark2_user_agent,
        override_variant: variant1,
        local_storage_variant: variant1,
        utm_source: non_eligible_utm_sources[0],
        memorized_variant: variant1,
        has_adjust_data: true
      }
    end

    it "prioritizes customer check" do
      expect(subject).not_to receive(:rand)
      result = subject.(
        customer: clark2_customer,
        **params.slice(
          :user_agent,
          :override_variant,
          :local_storage_variant,
          :utm_source,
          :memorized_variant,
          :has_adjust_data
        )
      )
      expect(result.variant).to eq variant2
    end

    it "prioritizes user agent check" do
      expect(subject).not_to receive(:rand)
      result = subject.(
        user_agent: clark1_user_agent,
        **params.slice(
          :override_variant,
          :local_storage_variant,
          :utm_source,
          :memorized_variant,
          :has_adjust_data
        )
      )
      expect(result.variant).to eq variant1
    end

    it "prioritizes override_variant check" do
      expect(subject).not_to receive(:rand)
      result = subject.(
        override_variant: variant2,
        **params.slice(
          :local_storage_variant,
          :utm_source,
          :memorized_variant,
          :has_adjust_data
        )
      )
      expect(result.variant).to eq variant2
    end

    it "prioritizes has_adjust_data check" do
      expect(subject).not_to receive(:rand)
      result = subject.(
        has_adjust_data: false,
        **params.slice(
          :local_storage_variant,
          :utm_source,
          :memorized_variant
        )
      )
      expect(result.variant).to eq variant1
    end

    it "prioritizes utm_source check" do
      expect(subject).not_to receive(:rand)
      result = subject.(
        local_storage_variant: variant2,
        **params.slice(
          :utm_source,
          :memorized_variant
        )
      )
      expect(result.variant).to eq variant1
    end

    it "prioritizes local_storage_variant check" do
      expect(subject).not_to receive(:rand)
      result = subject.(
        local_storage_variant: variant2,
        **params.slice(
          :memorized_variant
        )
      )
      expect(result.variant).to eq variant2
    end
  end
end
# rubocop:enable RSpec/SubjectStub
