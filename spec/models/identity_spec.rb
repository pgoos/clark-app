# == Schema Information
#
# Table name: identities
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  provider   :string
#  uid        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe Identity, type: :model do

  #
  # Setup
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  let(:identity) { build(:identity) }

  subject { identity }

  it { is_expected.to be_valid }

  #
  # Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Constants
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Attribute Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Plugins
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Concerns
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #
  it_behaves_like 'an auditable model'

  #
  # State Machine
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Scopes
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Associations
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Nested Attributes
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Validations
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Callbacks
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Instance Methods
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Class Methods
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  describe 'find_for_oauth' do
    subject { Identity.find_for_oauth(auth) }

    let(:auth) { double(provider: provider, uid: uid) }
    let(:provider) { 'some provider' }
    let(:uid) { 'some uid' }

    context 'when matching identity exists' do
      before { @matching_identity = create(:identity, provider: provider, uid: uid) }

      it { is_expected.to eq(@matching_identity) }
      it { expect{ subject }.not_to change{ Identity.count } }
    end

    context 'when no matching identity exists' do
      it { expect(subject.provider).to eq provider }
      it { expect(subject.uid).to eq uid }
      it { expect{ subject }.to change{ Identity.count }.by(1) }
    end
  end

end

