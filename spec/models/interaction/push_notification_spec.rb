# == Schema Information
#
# Table name: interactions
#
#  id           :integer          not null, primary key
#  type         :string
#  mandate_id   :integer
#  admin_id     :integer
#  topic_id     :integer
#  topic_type   :string
#  direction    :string
#  content      :text
#  metadata     :jsonb
#  acknowledged :boolean
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'rails_helper'

RSpec.describe Interaction::PushNotification, type: :model do
  # Setup ----------------------------------------------------------------------
  # Settings -------------------------------------------------------------------
  # Constants ------------------------------------------------------------------
  # Attribute Settings ---------------------------------------------------------
  # Plugins --------------------------------------------------------------------
  # Concerns -------------------------------------------------------------------
  # Scopes ---------------------------------------------------------------------
  # Associations ---------------------------------------------------------------
  # Nested Attributes ----------------------------------------------------------
  # Validations ----------------------------------------------------------------
  # Callbacks  -----------------------------------------------------------------
  # Instance Methods------------------------------------------------------------
  # Class Methods --------------------------------------------------------------
end
