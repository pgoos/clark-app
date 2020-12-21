# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retirement::Messenger::AnalysedJob, type: :job do
  it { is_expected.to be_a(ClarkJob) }

  describe ".perform" do
    let(:mandate)            { create(:mandate) }
    let(:product)            { create(:product, mandate: mandate) }
    let(:retirement_product) { create(:retirement_product, product: product) }
    let(:template_name)      { "retirement_product_analysed" }

    before do
      allow(OutboundChannels::Messenger::TransactionalMessenger)
        .to receive(:analysed).with(mandate, template_name, product.category)

      subject.perform(retirement_product.id, template_name)
    end

    it { expect(OutboundChannels::Messenger::TransactionalMessenger).to have_received(:analysed) }
  end
end
