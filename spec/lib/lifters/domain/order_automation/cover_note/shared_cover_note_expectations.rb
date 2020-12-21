# frozen_string_literal: true

RSpec.shared_context "shared cover note expectations" do
  subject { described_class.new(product, old_product) }

  let(:mandate) { create(:mandate, :with_user) }
  let(:product) { create(:product, mandate: mandate, contract_ended_at: Date.today - 2.days) }
  let(:old_product) { create(:product) }

  def check_for_checked_value(hash, checked_value)
    doc_name = "Unterschriebener Maklerauftrag liegt vor"
    broker_contract, remaining_docs = hash[:documents][:required_documents].partition { |d| d[:name] == doc_name }
    expect(broker_contract.first[:checked]).to eq(checked_value)
    expect(remaining_docs.count { |d| d[:checked] }).to eq(remaining_docs.count)
  end

  describe "#call" do
    context "application_data_sheet attribute" do
      context "mandate has state accepted" do
        let(:mandate) { create(:mandate, :accepted, :with_user) }

        it "has checked true everywhere" do
          check_for_checked_value(subject.call[:application_data_sheet], true)
        end
      end

      context "mandate has state NOT accepted" do
        it "has checked true everywhere" do
          check_for_checked_value(subject.call[:application_data_sheet], false)
        end
      end
    end
  end
end
