# == Schema Information
#
# Table name: tracking_adjust_events
#
#  id              :integer          not null, primary key
#  activity_kind   :string           not null
#  event_time      :datetime         not null
#  event_name      :string
#  params          :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  device_id       :integer
#  mandate_id      :integer
#  installation_id :string
#

require 'rails_helper'

RSpec.describe Tracking::AdjustEvent, type: :model do

  # Setup
  # ---------------------------------------------------------------------------------------

  let(:device) { FactoryBot.build(:device, installation_id: installation_id) }
  let(:installation_id) { "8eb7cfedef752d762a8280a66572b451006a2b6edf4096bef158415fda73e404" }
  let(:adid) { "adjust device identifier" }

  before "stub DB search for device" do
    allow(Device).to receive(:by_installation_id).and_return(OpenStruct.new(first: nil))
    allow(Device).to receive(:by_installation_id).with(installation_id).and_return(OpenStruct.new(first: device))
  end

  describe 'tracking adjust events' do
    let(:adjust_event) { Tracking::AdjustEvent.new(activity_kind: "some_kind", event_time: Time.zone.now, params: params) }
    let(:params) { { installation_id: installation_id } }

    def run_before_validation_on_create_callbacks
      adjust_event.set_associations
    end

    subject { run_before_validation_on_create_callbacks }

    context "when params contain existing installation_id of a user's device" do
      before do
        device.user = FactoryBot.build(:user, :with_mandate)
      end

      it { expect{ subject }.to change{ adjust_event.installation_id }.from(nil).to(installation_id) }
      it { expect{ subject }.to change{ adjust_event.device }.from(nil).to(device) }
      it { expect{ subject }.to change{ adjust_event.mandate }.from(nil).to(device.user.mandate) }
    end

    context "when params contain existing installation_id of a lead's device" do
      before do
        device.lead = FactoryBot.build(:lead, :with_mandate)
      end

      it { expect{ subject }.to change{ adjust_event.installation_id }.from(nil).to(installation_id) }
      it { expect{ subject }.to change{ adjust_event.device }.from(nil).to(device) }
      it { expect{ subject }.to change{ adjust_event.mandate }.from(nil).to(device.lead.mandate) }
    end

    context "when params contain non-existing installation_id" do
      before { params[:installation_id] = "this_installation_id_does_not_exist" }

      it { expect{ subject }.to change{ adjust_event.installation_id }.from(nil).to("this_installation_id_does_not_exist") }
      it { expect{ subject }.not_to change{ adjust_event.device } }
    end

    context "when params contain no installation_id" do
      before { params.delete(:installation_id) }

      it { expect{ subject }.not_to change{ adjust_event.installation_id } }

      it { expect{ subject }.not_to change{ adjust_event.device } }
    end
  end

  # Settings
  # ---------------------------------------------------------------------------------------

  # Constants
  # ---------------------------------------------------------------------------------------

  # Attribute Settings
  # ---------------------------------------------------------------------------------------

  # Plugins
  # ---------------------------------------------------------------------------------------

  # Concerns
  # ---------------------------------------------------------------------------------------

  # State Machine
  # ---------------------------------------------------------------------------------------

  # Scopes
  # ---------------------------------------------------------------------------------------

  include_examples 'between_scopeable', :created_at

  # Associations
  # ---------------------------------------------------------------------------------------

  # Nested Attributes
  # ---------------------------------------------------------------------------------------

  # Validations
  # ---------------------------------------------------------------------------------------

  it { expect(subject).to validate_presence_of(:activity_kind) }
  it { expect(subject).to validate_presence_of(:event_time) }
  it { expect(subject).to validate_presence_of(:params) }

  # Callbacks
  # ---------------------------------------------------------------------------------------

  # Instance Methods
  # ---------------------------------------------------------------------------------------

  describe '#set_sibling_mandate_ids_slowly' do
    subject { adjust_event.set_sibling_mandate_ids_slowly }

    let(:adjust_event) { create :tracking_adjust_event, params: { "adid" => adid }, mandate: mandate }
    let(:other_adjust_event) { create :tracking_adjust_event, params: { "adid" => other_adid }, mandate: other_mandate }
    let(:adid) { "some_adjust_identifier" }

    context 'when adjust_event has a mandate' do
      let(:mandate) { create :mandate }

      context 'when other_adjust_event has no mandate but same adid' do
        let(:other_mandate) { nil }
        let(:other_adid) { adid }

        it 'updates the mandate' do
          expect{ subject }.to change{ other_adjust_event.reload.mandate }.from(nil).to(mandate)
        end
      end

      context 'when other_adjust_event has a different mandate' do
        let(:other_mandate) { create :mandate }
        let(:other_adid) { adid }

        it 'does not change anything' do
          expect{ subject }.not_to change{ other_adjust_event.reload.mandate }
        end
      end

      context 'when other_adjust_event has no mandate but different adid' do
        let(:other_mandate) { nil }
        let(:other_adid) { "yet another adjust identifier" }

        it 'does not change anything' do
          expect{ subject }.not_to change{ other_adjust_event.reload.mandate }
        end
      end
    end

    context 'when adjust_event has no mandate' do
      let(:mandate) { nil }
      let(:other_mandate) { nil }
      let(:other_adid) { adid }

      it 'does not change anything' do
        expect{ subject }.not_to change{ other_adjust_event.reload.mandate }
      end
    end
  end

  describe "#enqueue_jobs" do
    subject{ adjust_event.send(:enqueue_jobs) }

    let!(:adjust_event) { create :tracking_adjust_event, params: { "some" => "params" } }

    it 'enqueues a CompleteAdjustEventMandateIdsOfSiblingsJob' do
      Timecop.freeze do
        expect { subject }.to enqueue_a(CompleteAdjustEventMandateIdsOfSiblingsJob).with(global_id(adjust_event)).to_run_at(15.minutes.from_now)
      end
    end

    it 'calls :try_set_mandate_by_adid_slowly on job execution' do
      perform_enqueued_jobs do
        expect_any_instance_of(Tracking::AdjustEvent).to receive(:set_sibling_mandate_ids_slowly).once
        subject
      end
    end
  end

  # Class Methods
  # ---------------------------------------------------------------------------------------

end

