# == Schema Information
#
# Table name: acquisition_partners
#
#  id              :integer          not null, primary key
#  username        :string
#  password_digest :string
#  enabled         :boolean          default(TRUE)
#  networks        :text             default([]), is an Array
#  meta            :jsonb            not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryBot.define do
  factory :acquisition_partner do
    username { "username" }
    password { "password" }
    networks { ["networkabc"] }
  end
end
