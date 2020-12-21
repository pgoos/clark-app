# frozen_string_literal: true

require "rails_helper"

RSpec.describe "admin updates the address" do
  let!(:address) { create(:address, mandate: mandate) }
  let(:active_at) { "" }
  let(:attributes) do
    {
      street:         "New Street",
      house_number:   "1",
      city:           "New City",
      zipcode:        "12345",
      apartment_size: 100,
      active_at:      active_at
    }
  end
  let(:send_notification) { false }
  let(:updater) { Domain::Addresses::Update.for_admin_update(address, attributes, send_notification) }

  before do
    allow(Features).to receive(:active?).and_call_original
    allow(Features).to receive(:active?).with(Features::MULTIPLE_ADDRESSES).and_return(true)
  end

  context "mandate state = accepted" do
    let(:mandate) { build :mandate, :accepted }

    context "When validates_addition_to_address" do
      before do
        allow(Settings).to(
          receive_message_chain("addition_to_address.validates_presence")
            .and_return(setting_enabled)
        )
        allow(Settings).to(
          receive_message_chain("addition_to_address.expose")
            .and_return(true)
        )
      end

      describe "enabled" do
        let(:setting_enabled) { true }

        it "returns error on empty addition_to_address" do
          updater.call
          expect(updater.address.errors[:addition_to_address]).not_to be_empty
        end
      end

      describe "disabled" do
        let(:setting_enabled) { false }

        it "updates address" do
          updated_address = updater.call
          expect(updated_address.street).to eq attributes[:street]
          expect(updated_address.addition_to_address).to be_nil
        end
      end
    end

    context "send_notification = true" do
      let(:send_notification) { true }

      context "valid active_at" do
        let(:active_at) { 1.day.from_now.to_s }

        it "updates address" do
          updated_address = updater.call
          expect(updated_address.street).to eq attributes[:street]
          expect(updated_address.house_number).to eq attributes[:house_number]
          expect(updated_address.house_number).to eq attributes[:house_number]
          expect(updated_address.zipcode).to eq attributes[:zipcode]
        end

        it "sends notification" do
          expect_any_instance_of(Domain::Addresses::Notify).to receive(:call)
          updater.call
        end

        it "saves address snapshot" do
          expect { updater.call }.to change(Address, :count).by(1)
        end

        it "activates address" do
          expect(updater.address.active).to eq true
        end

        it "accepts address" do
          expect(updater.address.accepted).to eq true
        end
      end

      context "active_at empty" do
        it "returns error" do
          updater.call
          expect(updater.address.errors).not_to be_empty
        end
      end
    end

    context "send_notification = 0" do
      let(:send_notification) { false }

      context "valid active_at" do
        let(:active_at) { 1.day.from_now.to_s }

        it "does not send notification" do
          expect_any_instance_of(Domain::Addresses::Notify).not_to receive(:call)
          updater.call
        end
      end

      context "active_at empty" do
        it "does not send notification" do
          expect_any_instance_of(Domain::Addresses::Notify).not_to receive(:call)
          updater.call
        end
      end
    end

    context "new attributes empty" do
      let(:attributes) { {} }

      it "does not update address" do
        expect(updater).not_to receive(:update)
        updater.call
      end
    end

    context "new attributes same as old attributes" do
      let(:attributes) { address.attributes }

      it "does not update address" do
        expect(updater).not_to receive(:update)
        updater.call
      end
    end
  end

  context "mandate state = created" do
    let(:mandate) { build :mandate, :created }

    it "updates address" do
      updated_address = updater.call
      expect(updated_address.mandate_id).to eq mandate.id
      expect(updated_address.street).to eq attributes[:street]
      expect(updated_address.zipcode).to eq attributes[:zipcode]
      expect(updated_address.house_number).to eq attributes[:house_number]
    end

    it "saves address snapshot" do
      expect { updater.call }.to change(Address, :count).by(1)
    end
  end

  context "mandate state = in_creation" do
    let(:mandate) { build :mandate, :in_creation }

    it "does not create address snapshot" do
      expect {
        updater.call
      }.to change(Address, :count).by(0)
    end
  end
end
