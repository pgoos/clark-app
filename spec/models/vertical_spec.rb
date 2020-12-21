# frozen_string_literal: true
# == Schema Information
#
# Table name: verticals
#
#  id         :integer          not null, primary key
#  state      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  ident      :string
#  name       :string
#

require "rails_helper"

RSpec.describe Vertical, type: :model do
  it_behaves_like "a commentable model"
  it_behaves_like "an activatable model"
  it_behaves_like "an auditable model"

  it "has a valid factory" do
    expect(build(:vertical)).to be_valid
  end

  let(:vertical) { build(:vertical) }

  describe "ActiveModel validations" do
    # Basic validations
    it { expect(vertical).to validate_presence_of(:name) }
    it { expect(vertical).to validate_uniqueness_of(:ident).allow_blank }
  end

  describe "ActiveRecord associations" do
    # Associations
    it { expect(vertical).to have_many(:categories).dependent(:restrict_with_error) }
    it { expect(vertical).to have_and_belong_to_many(:subcompanies).dependent(:restrict_with_error) }
  end
end
