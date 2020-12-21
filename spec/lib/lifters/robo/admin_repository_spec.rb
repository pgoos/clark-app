# frozen_string_literal: true

require "rails_helper"

describe Robo::AdminRepository do
  describe ".random" do
    let(:admins) { build_stubbed_list(:admin, 2) }

    context "with e-mail based admins" do
      before do
        allow(Admin).to receive(:where).with(email: ::RoboAdvisor::ADVICE_ADMIN_EMAILS).and_return(admins)
        allow(Admin).to receive(:where).with(id: ::RoboAdvisor::ADVICE_ADMIN_IDS).and_return(Admin.none)
      end

      it do
        expect(admins.map(&:id)).to include described_class.random
      end
    end

    context "with id based admins" do
      before do
        allow(Admin).to receive(:where).with(email: ::RoboAdvisor::ADVICE_ADMIN_EMAILS).and_return(Admin.none)
        allow(Admin).to receive(:where).with(id: ::RoboAdvisor::ADVICE_ADMIN_IDS).and_return(admins)
      end

      it do
        expect(admins.map(&:id)).to include described_class.random
      end
    end

    context "with no admin" do
      it do
        expect(described_class.random).to be_nil
      end
    end
  end
end
