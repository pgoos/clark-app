# frozen_string_literal: true

require "rails_helper"

RSpec.describe "rake ocr:upload_mandates", integration: true, type: :task do
  let(:ocr_service_double) { instance_double(::OCR::Service) }
  let!(:mandates) { create_list(:mandate, 2, :accepted, :with_address) }
  let!(:revoked_mandates) { create(:mandate, :revoked, :with_address) }

  before do
    mandates.second.addresses << create(:address)
  end

  it_behaves_like "a ocr data uploader" do
    let(:data) do
      addresses = Address.where(mandate: mandates)
      addresses.map do |address|
        mandate = address.mandate
        [
          "#{mandate.id}$#{address.id}",
          mandate.first_name,
          mandate.last_name,
          mandate.id,
          mandate.birthdate.strftime("%Y-%m-%d"),
          "#{address.street}, #{address.house_number}",
          address.zipcode,
          address.city,
          address.country_code
        ]
      end
    end
    let(:table) { ::OCR::MasterData::Schema::CUSTOMER_TABLE }
    let(:columns) { ::OCR::MasterData::Schema::CUSTOMER_COLUMNS }
  end
end
