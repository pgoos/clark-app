# frozen_string_literal: true

require "rails_helper"

describe ReoccurringAdviceJob, type: :job do
  describe ".perform" do
    let(:product) { create(:product, category: category) }

    context "with supported category" do
      let(:category) { create(:category_phv) }

      it do
        expect(Robo::Runner).to receive(:call).with(product)
        subject.perform(product.id)
      end
    end

    context "with unsupported category" do
      let(:category) { create(:category, ident: "not_implemented") }

      before do
        allow(Rails).to receive_message_chain(:logger, :info)
          .with("Category #{category.ident} not implemented. Skkiping advice for product #{product.id}")
        allow(Raven).to receive(:user_context).with(product_id: product.id, category: category.ident)
        allow(Raven).to receive(:capture_exception).with(NotImplementedError)
        allow(Robo::Runner).to receive(:call).with(product).and_raise(NotImplementedError)

        subject.perform(product.id)
      end

      it do
        expect(Rails).to have_received(:logger)
        expect(Raven).to have_received(:user_context)
        expect(Raven).to have_received(:capture_exception)
      end
    end
  end
end
