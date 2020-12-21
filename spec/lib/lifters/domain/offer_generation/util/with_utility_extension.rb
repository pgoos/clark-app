# frozen_string_literal: true

RSpec.shared_context "with utility extension" do
  let(:offer) { build_stubbed(:offer) }

  let(:with_utility_extension) do
    proc do |offer, utility_module|
      c = Class.new do
        include utility_module

        def initialize(offer)
          @offer = offer
        end

        attr_reader :offer
      end
      c.new(offer)
    end
  end
end
