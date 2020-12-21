# == Schema Information
#
# Table name: rule_appendices
#
#  id                :integer          not null, primary key
#  ident             :string
#  opportunity_value :integer
#  description       :text
#  audience          :text
#  content           :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

FactoryBot.define do
  factory :rule_appendix do
    ident { 'MyString' }
    opportunnity_value { 1 }
    description { 'MyString' }
    audience { 'MyString' }
  end
end
