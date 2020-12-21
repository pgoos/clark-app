# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateGkvProductJob do
  let(:positive_integer) { (100 * rand).round + 1 }
  let(:mandate) { instance_double(Mandate, id: positive_integer) }
  let(:gkv_product_creator_class) { Domain::Products::GkvProductCreator }
  let(:gkv_product_creator) { instance_double(gkv_product_creator_class) }

  before do
    allow(Mandate).to receive(:find).and_return(nil)
    allow(Mandate).to receive(:find).with(positive_integer).and_return(mandate)
    allow(gkv_product_creator_class).to receive(:new).with(mandate).and_return(gkv_product_creator)
  end

  it { is_expected.to be_a(ClarkJob) }

  it "should append to the queue 'mandate_accepted_tasks'" do
    expect(subject.queue_name).to eq("mandate_accepted_tasks")
  end

  it "should execute the product creation" do
    expect(gkv_product_creator).to receive(:create_gkv_product).with(no_args)
    subject.perform(mandate_id: positive_integer)
  end

  it "should do nothing, if the inquiry is gone" do
    expect(gkv_product_creator_class).not_to receive(:new)
    subject.perform(mandate_id: positive_integer + 1)
  end
end
