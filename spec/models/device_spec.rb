# == Schema Information
#
# Table name: devices
#
#  id                 :integer          not null, primary key
#  token              :string
#  os                 :string
#  os_version         :string
#  manufacturer       :string
#  model              :string
#  user_id            :integer
#  permissions        :json
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  arn                :string
#  installation_id    :string
#  advertiser_id      :string
#  advertiser_id_type :string
#

require 'rails_helper'

RSpec.describe Device, type: :model do

  #
  # Setup
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

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

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:lead).with_primary_key('installation_id').with_foreign_key('installation_id') }

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
  it { should validate_uniqueness_of(:token) }
  it { should validate_uniqueness_of(:installation_id) }
  it { should validate_presence_of(:installation_id) }
  it { should validate_presence_of(:os) }
  it { should validate_presence_of(:manufacturer) }
  it { should validate_presence_of(:os_version) }
  it { should validate_presence_of(:model) }
  it { is_expected.to have_db_index(:token) }

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

end

