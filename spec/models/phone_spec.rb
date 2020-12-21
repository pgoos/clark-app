# frozen_string_literal: true

# == Schema Information
#
# Table name: phones
#
#  id                 :integer          not null, primary key
#  number             :string
#  verification_token :string
#  token_created_at   :datetime
#  verified_at        :datetime
#  primary            :boolean          default(FALSE)
#  mandate_id         :integer
#  created_at         :datetime
#  updated_at         :datetime
#

require "rails_helper"

RSpec.describe Phone, type: :model do
  subject(:phone) { build :phone }

  it { is_expected.to be_valid }

  it { is_expected.to belong_to(:mandate) }

  it { is_expected.to validate_presence_of(:number) }
  it { is_expected.to validate_presence_of(:mandate) }

  it_behaves_like "a model with callbacks", :before, :update,
                  :mark_unverified_if_number_changed
  it_behaves_like "a model with localized phone number validation on", :number

  context "when default country code is DE" do
    before { stub_const("DEFAULT_COUNTRY_CODE", :de) }

    it_behaves_like "a model with normalized locale phone number field", :number, "+491771661253"
  end

  context "when default country code is AT" do
    before { stub_const("DEFAULT_COUNTRY_CODE", :at) }

    it_behaves_like "a model with normalized locale phone number field", :number, "+431771661253"
  end

  it "marks record as unverified if the number changes" do
    expect(phone).to receive(:mark_unverified_if_number_changed).and_call_original
    new_valid_number = "015143389482"
    phone.verified_at = Time.zone.now
    phone.save
    phone.number = new_valid_number
    phone.save
    expect(phone.verified_at).to be_nil
  end

  it "marks record as invalid for incorrect phone number" do
    phone.number = "11dfjheir89"
    expect(phone.valid?).to be_falsey
  end

  context "when the number includes prefix without +" do
    {
      de: "49",
      at: "43"
    }.each do |code, prefix|
      it "formats the number correctly for country code #{code}" do
        stub_const("DEFAULT_COUNTRY_CODE", code)

        phone_number = "#{prefix}1771233294"
        phone.number = phone_number
        phone.save

        expect(phone.number).to eq("+#{phone_number}")
      end
    end
  end
end
