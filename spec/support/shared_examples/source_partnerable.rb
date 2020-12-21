# frozen_string_literal: true

RSpec.shared_examples "a source partnerable model" do
  let(:instance_name) { ActiveModel::Naming.singular described_class }
  let(:instance)      { FactoryBot.build instance_name }

  describe "public instance methods" do
    it "defines accessor for network" do
      instance.network = "test_net"
      expect(instance.network).to eq "test_net"
      expect(instance.source_data).to eq("adjust" => {"network" => "test_net"})
    end

    it "defines accessor for source_campaign" do
      instance.source_campaign = "test_camp"
      expect(instance.source_campaign).to eq "test_camp"
      expect(instance.source_data).to eq("adjust" => {"campaign" => "test_camp"})
    end

    it "defines accessor for utm_content" do
      instance.utm_content = "test_content"
      expect(instance.utm_content).to eq "test_content"
      expect(instance.source_data).to eq("adjust" => {"adgroup" => "test_content"})
    end

    it "defines accessor for utm_term" do
      instance.utm_term = "test_term"
      expect(instance.utm_term).to eq "test_term"
      expect(instance.source_data).to eq("adjust" => {"creative" => "test_term"})
    end

    it "defines accessor for partner_customer_id" do
      instance.partner_customer_id = "test_id"
      expect(instance.partner_customer_id).to eq "test_id"
      expect(instance.source_data).to eq("partner_customer_id" => "test_id")
    end
  end
end
