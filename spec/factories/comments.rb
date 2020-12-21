# == Schema Information
#
# Table name: comments
#
#  id               :integer          not null, primary key
#  admin_id         :integer
#  commentable_id   :integer
#  commentable_type :string
#  message          :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

FactoryBot.define do
  factory :comment do
    admin { nil }
    commentable { nil }
    message { "MyString" }
  end

end
