# frozen_string_literal: true
# == Schema Information
#
# Table name: plan_filters
#
#  id          :integer          not null, primary key
#  category_id :integer
#  key         :string
#  values      :text             is an Array
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require "rails_helper"

RSpec.describe PlanFilter, type: :model do
  context "attributes' validations" do
    it { is_expected.to belong_to(:category) }

    it { is_expected.to have_db_index(:category_id) }

    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_presence_of(:values) }
    it { is_expected.to validate_presence_of(:category_id) }

    it { is_expected.to allow_value([1, 2, 3]).for(:values) }
  end

  context "delegations" do
    it { is_expected.to delegate_method(:category_name).to(:category).as(:name) }
  end
end
