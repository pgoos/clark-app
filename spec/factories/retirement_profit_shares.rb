# frozen_string_literal: true
# == Schema Information
#
# Table name: retirement_profit_shares
#
#  id                      :integer          not null, primary key
#  retirement_age          :integer
#  profit_share_percentage :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#


FactoryBot.define do
  factory :retirement_profit_share, class: "Retirement::ProfitShare" do
  end
end
