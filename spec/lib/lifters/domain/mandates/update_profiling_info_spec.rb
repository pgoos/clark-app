# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Mandates::UpdateProfilingInfo do
  subject(:update) { described_class.new }

  let(:address) { build :address, accepted: false }
  let!(:mandate) { create :mandate, :created, :wizard_profiled, active_address: address }

  before do
    allow(Features).to receive(:active?).and_call_original
    allow(Features).to receive(:active?).with(Features::MULTIPLE_ADDRESSES).and_return(true)
  end

  context "with mandate attributes" do
    context "with new attributes" do
      it "updates mandates attributes" do
        update.(mandate, first_name: "New Name")

        expect(mandate.first_name).to eq "New Name"
      end
      it "creates business_event" do
        expect(BusinessEvent).to receive(:audit).with(mandate, "update")

        update.(mandate, first_name: "John")
      end
    end

    context "with same attributes" do
      it "does not update mandate" do
        expect {
          update.(mandate, first_name: mandate.first_name)
        }.not_to(change { mandate.addresses.count })
      end
      it "does not create business_event" do
        expect(BusinessEvent).not_to receive(:audit)

        update.(mandate, first_name: mandate.first_name)
      end
    end
  end

  describe "Settings.profile.track_update" do
    let!(:set_setting) do
      allow(Settings).to receive_message_chain("profile.track_update")
        .and_return(track_update)
    end

    before { update.(mandate, first_name: "New Name") }

    context "when setting is enabled" do
      let(:track_update) { true }

      it "sets profile_updated flag" do
        expect(mandate.info["profile_updated"]).to be_truthy
      end
    end

    context "when setting is disabled" do
      let(:track_update) { false }

      it "doesn't set profile_updated flag" do
        expect(mandate.info["profile_updated"]).to be_falsey
      end
    end
  end

  context "with address attributes" do
    let(:address_attrs) do
      {
        street: "New Street",
        house_number: "10",
        city: "New city",
        zipcode: "12345",
        country_code: "DE",
        apartment_size: 10,
        active_at: "2020-03-20",
      }.with_indifferent_access
    end

    context "and multiple addresses are enabled" do
      subject(:update) { described_class.new }

      context "when existing address is accepted" do
        let(:address) { create :address, accepted: true }

        it "creates new address" do
          update.(mandate, address_attrs)
          expect(mandate.addresses.count).to eq 2
          new_address = mandate.addresses.last
          expect(new_address).not_to eq address
          expect(new_address.street).to eq "New Street"
          expect(new_address.apartment_size).to eq 10
          expect(new_address).not_to be_active
          expect(new_address).not_to be_accepted
        end

        it "creates business_event" do
          expect(BusinessEvent).to receive(:audit).with(mandate, "update")

          update.(mandate, first_name: "John")
        end

        context "and mandate is not accepted nor created" do
          it "updates current address" do
            mandate = create :mandate, :in_creation, active_address: address
            update.(mandate, address_attrs)
            expect(mandate.addresses.count).to eq 1
            expect(address.reload.street).to eq "New Street"
          end

          it "provides a newly built address on the fly, if there is no existing address" do
            mandate = create :mandate, :in_creation, addresses: []
            update.(mandate, address_attrs)
            mandate.reload
            addresses = mandate.addresses
            expect(addresses.count).to eq 1
            expect(addresses.last.street).to eq "New Street"
          end
        end

        context "and params are the same" do
          let(:address) { create :address, address_attrs.merge(accepted: true) }

          it "does not create a new address" do
            expect {
              update.(mandate, address_attrs)
            }.not_to(change { mandate.addresses.count })
          end

          it "does not create business_event" do
            expect(BusinessEvent).not_to receive(:audit).with(mandate, "update")

            update.(mandate, address_attrs)
          end
        end
      end

      context "when current address is not accepted" do
        it "updates current address" do
          update.(mandate, address_attrs)
          expect(mandate.addresses.count).to eq 1
          expect(address.reload.street).to eq "New Street"
        end
      end

      context "with invalid attributes" do
        let(:address_attrs) { {first_name: "", street: ""}.with_indifferent_access }
        it "returns list of errors" do
          errors = update.(mandate, address_attrs)
          expect(errors).to be_a Hash
          expect(errors).to have_key :first_name
          expect(errors).to have_key :street
        end
      end
    end

    context "and multiple addresses are disabled" do
      it "updates existing address" do
        update.(mandate, address_attrs)
        expect(mandate.addresses.count).to eq 1
        expect(address.reload.street).to eq "New Street"
      end
    end
  end

  context "with new phone_number attributes" do
    let(:phone_number) { "+49#{ClarkFaker::PhoneNumber.phone_number}" }
    let(:phone_attributes) { {number: phone_number, mandate_id: mandate.id, primary: true} }

    it "create new primary phone_number" do
      expect { update.(mandate, phone: phone_number) }.to change { Phone.where(phone_attributes).count }.by(1)
    end
  end
end
