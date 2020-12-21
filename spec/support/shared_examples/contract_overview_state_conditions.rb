# frozen_string_literal: true

RSpec.shared_examples " a contract overview products with state conditions" do
  context "when product is in state customer_provided" do
    let!(:product) { setup_product :customer_provided }

    it { expect(subject.all(mandate)).to include product }
  end

  context "when product is in state details_available" do
    let!(:product) { setup_product :details_available }

    it { expect(subject.all(mandate)).to include product }
  end

  context "when product is canceled" do
    let!(:product) { setup_product :canceled }

    it { expect(subject.all(mandate)).not_to include product }
  end

  context "when product is terminated" do
    let!(:product) { setup_product :terminated }

    it { expect(subject.all(mandate)).to include product }
  end

  context "when product is offered" do
    let!(:product) { setup_product :offered }

    it { expect(subject.all(mandate)).not_to include product }
  end
end
