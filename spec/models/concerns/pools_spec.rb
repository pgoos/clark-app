# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pools do
  subject { Class.new { include Pools } }

  it { is_expected.to be_const_defined(:POOL_FONDS_FINANZ) }
  it { is_expected.to be_const_defined(:POOL_QUALITY_POOL) }
  it { is_expected.to be_const_defined(:POOL_DIRECT_AGREEMENT) }
  it { is_expected.to be_const_defined(:POOL_ARISECUR) }

  it { is_expected.to respond_to(:fonds_finanz?) }
  it { is_expected.to respond_to(:quality_pool?) }
  it { is_expected.to respond_to(:direct_agreement?) }
  it { is_expected.to respond_to(:arisecur?) }
  it { is_expected.to respond_to(:active_pools) }

  context "pools configured from settings" do
    before do
      pool_settings.each do |key, value|
        allow(Settings).to receive_message_chain(:pools, key).and_return(value)
      end
    end

    let(:pool_settings) do
      {
        "fonds_finanz" => true,
        "quality_pool" => true,
        "direct_agreement" => false,
        "arisecur" => false
      }
    end

    describe "#active_pools" do
      it "returns list of active pools" do
        expect(subject.active_pools).to match_array(pool_settings.keep_if { |_k, v| v }.keys)
      end
    end
  end
end
