# frozen_string_literal: true

require "rails_helper"

RSpec.describe Address, type: :model do
  subject(:address) { build :address, mandate: mandate, country_code: Settings.validates_zipcode.country_code }

  let(:mandate) { build :mandate }

  it do
    expect(subject).to validate_inclusion_of(:country_code)
      .in_array(ISO3166::Country.codes)
  end

  %i[street house_number zipcode city addition_to_address].each do |attr|
    it { expect(subject).not_to validate_presence_of(attr) }
  end

  RSpec.shared_examples "configurable_validation" do |attr, setting_path|
    describe "##{attr}" do
      before do
        allow(Settings).to(
          receive_message_chain(setting_path)
            .and_return(setting_enabled)
        )
      end

      context "When #{attr} validation disabled" do
        let(:setting_enabled) { false }

        it { expect(subject).not_to validate_presence_of(attr) }
      end

      context "When #{attr} validation enabled" do
        let(:setting_enabled) { true }

        it { expect(subject).to validate_presence_of(attr) }
      end
    end
  end

  RSpec.shared_examples "validates_zipcode" do
    before do
      allow(Settings).to receive_message_chain(:validates_zipcode, :country_code).and_return(country_code)
    end

    context "when country_code is DE" do
      let(:country_code) { "DE" }

      it "validates 5 digit code" do
        subject.assign_attributes(zipcode: "12345")
        expect(subject).to be_valid
      end

      it "refute invalid code" do
        subject.assign_attributes(zipcode: "1234")
        expect(subject).not_to be_valid
        expect(subject.errors[:zipcode]).to match_array([I18n.t("errors.messages.invalid_zipcode")])
      end
    end

    context "when country_code is AT" do
      let(:country_code) { "AT" }

      it "validates 4 digit code" do
        subject.assign_attributes(zipcode: "1234")
        expect(subject).to be_valid
      end

      it "refute invalid code" do
        subject.assign_attributes(zipcode: "12345")
        expect(subject).not_to be_valid
        expect(subject.errors[:zipcode]).to match_array([I18n.t("errors.messages.invalid_zipcode")])
      end
    end
  end

  context "when mandate on profiling step" do
    let(:mandate) { build :mandate, :wizard_profiled }

    %i[street house_number zipcode city].each do |attr|
      it { expect(subject).to validate_presence_of(attr) }
    end

    include_examples(
      "configurable_validation",
      :addition_to_address,
      "addition_to_address.validates_presence"
    )

    it "validates that the zipcode is valid" do
      subject.zipcode = "123456789"
      expect(subject).not_to be_valid
    end

    it_behaves_like "validates_zipcode"
  end

  context "when mandate on confirming step" do
    let(:mandate) { build :mandate, :wizard_confirmed }

    %i[street house_number zipcode city].each do |attr|
      it { expect(subject).to validate_presence_of(attr) }
    end

    include_examples(
      "configurable_validation",
      :addition_to_address,
      "addition_to_address.validates_presence"
    )

    it "validates that the zipcode is valid" do
      subject.zipcode = "123456789"
      expect(subject).not_to be_valid
    end

    it_behaves_like "validates_zipcode"
  end

  context "when mandate is freebie" do
    let(:mandate) { build :mandate, :freebie }

    %i[street house_number zipcode city].each do |attr|
      it { expect(subject).to validate_presence_of(attr) }
    end

    include_examples(
      "configurable_validation",
      :addition_to_address,
      "addition_to_address.validates_presence"
    )

    it "validates that the zipcode is valid" do
      subject.zipcode = "123456789"
      expect(subject).not_to be_valid
    end

    it_behaves_like "validates_zipcode"
  end

  it_behaves_like "a model with callbacks", :after, :initialize, :default_values

  describe ".activatable" do
    subject { described_class.activatable }

    let!(:address) { create :address, :inactive, :accepted, mandate: mandate, active_at: 1.day.ago }
    let(:mandate) { create :mandate, :accepted }

    it { is_expected.to include address }

    context "with inaccepted mandate" do
      let(:mandate) { create :mandate, :created }

      it { is_expected.not_to include address }
    end

    context "with active address" do
      let!(:address) { create :address, :active, :accepted, mandate: mandate, active_at: 1.day.ago }

      it { is_expected.not_to include address }
    end

    context "with active_at in the future" do
      let!(:address) do
        create :address, :inactive, :accepted, mandate: mandate, active_at: Time.zone.today + 1.day
      end

      it { is_expected.not_to include address }
    end
  end

  describe "#activate!" do
    context "with another active address" do
      subject(:address) { create :address, :inactive, mandate: mandate }

      let(:mandate) { create :mandate, active_address: previous_address }
      let(:previous_address) { build :address, :active }

      it "deactivates previous address" do
        address.activate!
        expect(address).to be_active
        expect(previous_address.reload).not_to be_active
      end
    end

    context "with the same active address" do
      let!(:mandate) do
        create(
          :mandate,
          active_address: build(
            :address,
            active: true,
            active_at: Time.zone.today
          )
        )
      end

      let!(:address) { Address.find(mandate.active_address.id) }

      it "doesn't change active address state" do
        address.activate!
        expect(address.reload).to be_active
      end

      it "doesn't publish 'updated' event" do
        expect(Mandate).not_to(
          receive(:publish_event).with(instance_of(Mandate), "updated", "update")
        )

        address.activate!
      end
    end
  end

  describe "#notifiable?" do
    subject do
      build :address, mandate: mandate, insurers_notified: insurers_notified, active_at: active_at
    end

    let(:mandate) { build :mandate, :accepted }
    let(:active_at) { Time.zone.today }
    let(:insurers_notified) { false }

    it { is_expected.to be_notifiable }

    context "when mandate is not accepted" do
      let(:mandate) { build :mandate, :created }

      it { is_expected.not_to be_notifiable }
    end

    context "when active_at is in future" do
      let(:active_at) { Time.zone.today + 1.day }

      it { is_expected.to be_notifiable }
    end

    context "when active_at is in the past" do
      let(:active_at) { 1.day.ago }

      it { is_expected.to be_notifiable }
    end

    context "when active_at is blank" do
      let(:active_at) { nil }

      it { is_expected.not_to be_notifiable }
    end

    context "when insurers have been already notified" do
      let(:insurers_notified) { true }

      it { is_expected.not_to be_notifiable }
    end
  end

  context "before validation" do
    it "normalizes attributes" do
      expect(Domain::Addresses::Normalizer).to receive(:call).with(address.attributes)
      address.validate
    end
  end

  context "address_auditable module behavior" do
    subject { create :address, mandate: mandate }

    let(:address_attributes) { attributes_for(:address).slice(:city, :house_number, :street, :zipcode) }

    let(:created_metadata) do
      {
        id: {old: nil, new: instance_of(Integer)},
        city: {old: nil, new: address_attributes[:city]},
        house_number: {old: nil, new: address_attributes[:house_number]},
        street: {old: nil, new: address_attributes[:street]},
        zipcode: {old: nil, new: address_attributes[:zipcode]}
      }
    end

    let(:previous_business_event) do
      create :business_event,
             entity_id: mandate.id,
             entity_type: "Mandate",
             action: "update_address",
             metadata: created_metadata.merge(id: {old: nil, new: Address.order(:id).last&.id || 1})
    end

    let(:next_created_metadata) do
      {
        id: {old: previous_business_event.metadata["id"]["new"], new: instance_of(Integer)},
        city: {old: previous_business_event.metadata["city"]["new"], new: address_attributes[:city]},
        house_number: {
          old: previous_business_event.metadata["house_number"]["new"],
          new: address_attributes[:house_number]
        },
        street: {old: previous_business_event.metadata["street"]["new"], new: address_attributes[:street]},
        zipcode: {old: previous_business_event.metadata["zipcode"]["new"], new: "61068"}
      }
    end

    let(:updated_metadata) do
      {
        city: {old: address_attributes[:city], new: address_attributes[:city]},
        house_number: {old: address_attributes[:house_number], new: address_attributes[:house_number]},
        street: {old: address_attributes[:street], new: "New Street Name"},
        zipcode: {old: address_attributes[:zipcode], new: "61000"}
      }
    end

    let(:deleted_metadata) do
      {
        city: {old: address_attributes[:city], new: nil},
        house_number: {old: address_attributes[:house_number], new: nil},
        street: {old: address_attributes[:street], new: nil},
        zipcode: {old: address_attributes[:zipcode], new: nil}
      }
    end

    let(:changed_attributes) { {zipcode: "61000", street: "New Street Name"} }

    it "triggers new business event on address create" do
      expect(BusinessEvent).to receive(:audit).with(mandate, "update_address", created_metadata)

      subject
    end

    it "simulates business event as update on next address create" do
      mandate.save
      previous_business_event.reload
      expect(BusinessEvent).to receive(:audit).with(mandate, "update_address", next_created_metadata)

      create :address, mandate: mandate, zipcode: "61068"
    end

    it "triggers new business event on address update" do
      address = subject.reload
      updated_metadata[:id] = {old: address[:id], new: address[:id]}

      expect(BusinessEvent).to receive(:audit)
        .with(mandate, "update_address", updated_metadata)
      address.update(changed_attributes)
    end

    it "triggers new business event on address destroy" do
      address = subject.reload
      deleted_metadata[:id] = {old: address[:id], new: nil}

      expect(BusinessEvent).to receive(:audit).with(mandate, "update_address", deleted_metadata)
      address.destroy
    end

    it "does not trigger business event when fields for audit did not updated" do
      address = subject.reload
      updated_metadata[:id] = {old: address[:id], new: address[:id]}

      expect(BusinessEvent).not_to receive(:audit)
        .with(mandate, "update_address", updated_metadata)
      address.update(accepted: true)
    end
  end
end
