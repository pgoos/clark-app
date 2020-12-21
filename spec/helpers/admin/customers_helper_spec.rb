# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CustomersHelper, type: :helper do
  # rubocop:disable RSpec/LeakyConstantDeclaration
  class Dummy
    include Admin::CustomersHelper

    # rubocop:disable Lint/UnusedMethodArgument
    def content_tag(name, content=nil, options=nil, &block)
      block_given? ? yield : content
    end
    # rubocop:enable Lint/UnusedMethodArgument
  end
  # rubocop:enable RSpec/LeakyConstantDeclaration

  subject { Dummy.new }

  describe "#customer_badge" do
    let(:customer_badge) { subject.customer_badge(mandate) }

    context "with no mandate" do
      let(:mandate) { nil }

      it { expect(customer_badge).to be_nil }
    end

    context "with mandate acquired by partner" do
      let(:owner_ident) { "owner123" }
      let(:mandate) do
        double(
          :mandate,
          acquired_by_partner?: true,
          owner_ident: owner_ident
        )
      end

      it { expect(customer_badge).to match(/#{owner_ident.titleize}/) }
    end

    context "with clark 2.0 mandate" do
      let(:customer_state) { "prospect" }
      let(:mandate) do
        double(
          :mandate,
          acquired_by_partner?: false,
          customer_state: customer_state
        )
      end

      it do
        expect(customer_badge)
          .to match(/#{described_class::CLARK2_TEXT.titleize}/)
      end
    end

    context "with common mandate" do
      let(:customer_state) { nil }
      let(:mandate) do
        double(
          :mandate,
          acquired_by_partner?: false,
          customer_state: customer_state
        )
      end

      it { expect(customer_badge).to be_nil }
    end
  end
end
