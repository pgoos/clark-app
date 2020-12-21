# == Schema Information
#
# Table name: tracking_events
#
#  id         :uuid             not null, primary key
#  visit_id   :uuid
#  user_id    :integer
#  name       :string
#  properties :jsonb
#  time       :datetime
#  mandate_id :integer
#

require 'rails_helper'

RSpec.describe Tracking::Event, type: :model do
  # Setup
  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  # State Machine
  # Scopes
  include_examples 'between_scopeable', :time

  # Associations
  it { expect(subject).to belong_to(:user) }
  it { expect(subject).to belong_to(:mandate) }

  # Nested Attributes
  # Validations
  # Callbacks
  # Instance Methods

  describe "#try_set_mandate_by_visitor_id_slowly" do
    subject{ event.try_set_mandate_by_visitor_id_slowly }

    let(:event) { create :tracking_event, visit_id: visit.id, mandate: mandate }
    let(:visit) { create :tracking_visit, visitor_id: visitor_id, mandate: nil }
    let(:visitor_id) { "ab123456-1abc-123a-ab12-ab0ab01a1a12" }

    context 'when event has no mandate' do
      let(:mandate) { nil }

      context 'when another visit with same visitor_id  exists' do
        before { create :tracking_visit, visitor_id: visitor_id, mandate: other_mandate }

        context 'when other visit has mandate' do
          let(:other_mandate) { create :mandate }

          it "sets the other mandate as the event's mandate" do
            expect{ subject }.to change{ event.mandate }.from(nil).to(other_mandate)
          end
        end

        context 'when other visit has no mandate' do
          let(:other_mandate) { nil }

          it "sets the other mandate as the event's mandate" do
            expect{ subject }.not_to change{ event.mandate }
          end
        end
      end

      context 'when another event with a visit with the same visitor_id' do
        before do
          other_visit = create :tracking_visit, visitor_id: visitor_id, mandate: nil
          create :tracking_event, visit_id: other_visit.id, mandate: other_mandate
        end

        context 'when other visit has mandate' do
          let(:other_mandate) { create :mandate }

          it "sets the other mandate as the event's mandate" do
            expect{ subject }.to change{ event.mandate }.from(nil).to(other_mandate)
          end
        end

        context 'when other visit has no mandate' do
          let(:other_mandate) { nil }

          it "sets the other mandate as the event's mandate" do
            expect{ subject }.not_to change{ event.mandate }
          end
        end
      end
    end

    context 'when event has mandate already' do
      let(:mandate) { create :mandate }

      # test only one of the many cases in which nothing should change now

      context 'when another visit with same visitor_id and mandate exists' do
        before { create :tracking_visit, visitor_id: visitor_id, mandate: other_mandate }
        let(:other_mandate) { create :mandate }

        it 'does not change the mandate' do
          expect{ subject }.not_to change{ event.mandate }
        end
      end
    end
  end

  # Class Methods
end
