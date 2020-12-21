# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::Helpers::AccountHelpers, :integration do
  before :all do
    class AccountHelpersDummy
      include ClarkAPI::Helpers::AccountHelpers

      def initialize(warden_double)
        @env_double = {"warden" => warden_double}
      end

      def env
        @env_double
      end

      def init_current_user
        @current_user = instance_double(User)
      end
    end
  end

  subject { AccountHelpersDummy.new(warden_double) }

  let(:warden_double) { double('warden') }
  let(:lead_id) { (10 * rand).round }
  let(:lead) { instance_double(Lead) }
  let(:mandate) { instance_double(Mandate) }

  it "includes the helpers" do
    expect(subject).to be_a(described_class)
  end
end
