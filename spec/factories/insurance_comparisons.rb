# == Schema Information
#
# Table name: insurance_comparisons
#
#  id                       :integer          not null, primary key
#  uuid                     :string
#  mandate_id               :integer
#  category_id              :integer
#  created_at               :datetime
#  updated_at               :datetime
#  expected_insurance_begin :datetime
#  opportunity_id           :integer
#  meta                     :jsonb
#

FactoryBot.define do
  factory :insurance_comparison do
    opportunity
  end
end
