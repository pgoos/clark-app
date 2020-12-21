require "rails_helper"

RSpec.describe Domain::Messenger::InteractionProcessor do
  let(:mandate) { create(:mandate) }
  let(:message) { create(:interaction_message, mandate: mandate) }
  let(:product) { create(:product) }
  let!(:advice)  { create(:advice, topic: product) }
  let(:options) { {context_type: "Product", context_id: product.id} }

  context "acknowledge related advice" do
    it "does nothing without context_type" do
      options.except!(:context_type)
      expect(described_class.process_message(message, options)).to eq(false)
    end

    it "does nothing without context_id" do
      options.except!(:context_id)
      expect(described_class.process_message(message, options)).to eq(false)
    end

    it "does nothing when context_type is nil" do
      options[:context_type] = nil
      expect(described_class.process_message(message, options)).to eq(false)
    end

    it "does nothing when context_id is nil" do
      options[:context_id] = nil
      expect(described_class.process_message(message, options)).to eq(false)
    end

    it "throws an error when context is not valid" do
      error = StandardError.new("Mismatch context: Bananas")
      expect(Raven).to receive(:capture_exception).with(error)
      options[:context_type] = "Bananas"
      expect(described_class.process_message(message, options)).to eq(false)
    end

    it "acknowledged the advices" do
      expect(described_class.process_message(message, options)).to eq(true)

      advice.reload

      expect(advice.acknowledged).to eq(true)
    end

    it "updates the message to have the product as topic" do
      expect(described_class.process_message(message, options)).to eq(true)

      message.reload
      expect(message.topic).to eq(product)
    end
  end
end
