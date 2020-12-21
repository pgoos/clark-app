# frozen_string_literal: true

require "rails_helper"
RSpec.describe Domain::Inquiries::SubCompanyGrouping do
  let(:vertical_1) { create(:vertical, name: "vertical_1") }
  let(:vertical_2) { create(:vertical, name: "vertical_2") }
  let(:vertical_3) { create(:vertical, name: "vertical_3") }
  let(:phv_category) { create(:category_phv, vertical: vertical_1) }
  let(:gkv_category) { create(:category_gkv, vertical: vertical_2) }
  let(:category_without_subcompany) { create(:category, vertical: vertical_3) }
  let!(:allianz_company) { create(:company, name: "Allianz") }
  let!(:allianz_phv_subcompany) do
    create(:subcompany, verticals: [vertical_1], company: allianz_company)
  end
  let!(:allianz_gkv_subcompany) do
    create(:subcompany, verticals: [vertical_2], company: allianz_company)
  end
  let(:mandate) { create(:mandate) }

  before do
    @inquiry = create(:inquiry, mandate: mandate, company: allianz_company)
    @inquiry.state = :pending
    @inquiry.save
  end

  it "skips an inquiry that is not in a pending or in creation state" do
    @inquiry.categories << phv_category
    @inquiry.state = :contacted
    @inquiry.save!
    described_class.group_inquiries([@inquiry])
    expect(mandate.inquiries.map(&:company_id)).to include(allianz_company.id)
    expect(mandate.inquiries.map(&:subcompany_id)).not_to include(allianz_phv_subcompany.id)
  end

  it "skips an inquiry that does not have a category" do
    described_class.group_inquiries([@inquiry])
    expect(mandate.inquiries.map(&:company_id)).to include(allianz_company.id)
    expect(mandate.inquiries.map(&:subcompany_id)).to eq([nil])
  end

  it "creates inquiries mapping for each sub company of the categories in an inquiry if only " \
     "one subcompany available for a category" do
    @inquiry.categories << phv_category
    @inquiry.categories << gkv_category
    @inquiry.save
    described_class.group_inquiries([@inquiry])
    expect(mandate.inquiries.count).to eq(2)
    expect(mandate.inquiries.map(&:subcompany_id)).to include(allianz_phv_subcompany.id)
    expect(mandate.inquiries.map(&:subcompany_id)).to include(allianz_gkv_subcompany.id)
  end

  it "chooses the principle sub company if more than one exists and one of them is " \
     "marked as principal" do
    @inquiry.categories << phv_category
    @inquiry.save
    principal_allianz_phv_subcompany = create(
      :subcompany, verticals: [vertical_1], company: allianz_company, principal: true
    )
    described_class.group_inquiries([@inquiry])
    expect(mandate.inquiries.map(&:subcompany_id)).to include(principal_allianz_phv_subcompany.id)
    expect(mandate.inquiries.map(&:subcompany_id)).not_to include(allianz_phv_subcompany.id)
  end

  it "will not choose a sub company if more than one exists and no one of them is marked " \
     "as principal" do
    @inquiry.categories << phv_category
    @inquiry.save
    another_allianz_phv_subcompany = create(
      :subcompany, verticals: [vertical_1], company: allianz_company
    )
    described_class.group_inquiries([@inquiry])
    expect(mandate.inquiries.map(&:company_id)).to include(allianz_company.id)
    expect(mandate.inquiries.map(&:subcompany_id)).not_to include(another_allianz_phv_subcompany.id)
    expect(mandate.inquiries.map(&:subcompany_id)).not_to include(allianz_phv_subcompany.id)
  end

  it "deletes the original inquiry if all categories are mapped to subcompanies" do
    @inquiry.categories << phv_category
    @inquiry.categories << gkv_category
    @inquiry.save
    described_class.group_inquiries([@inquiry])
    expect(mandate.inquiries.map(&:id)).not_to include(@inquiry.id)
  end

  it "keeps the original inquiry if not all categories are mapped to subcompany" do
    @inquiry.categories << phv_category
    @inquiry.categories << gkv_category
    @inquiry.categories << category_without_subcompany
    @inquiry.save
    described_class.group_inquiries([@inquiry])
    expect(mandate.inquiries.count).to eq(3)
    expect(mandate.inquiries.map(&:id)).to include(@inquiry.id)
  end

  it "keeps the original inquiry and does not add a subcompany to it if not all categories " \
     "are mapped to subcompany" do
    @inquiry.categories << phv_category
    @inquiry.categories << gkv_category
    @inquiry.categories << category_without_subcompany
    @inquiry.save
    described_class.group_inquiries([@inquiry])
    expect(@inquiry.reload.subcompany).to be_nil
  end

  context "when inquiry is gkv" do
    before do
      allianz_company.update(national_health_insurance_premium_percentage: 10)
    end

    context "when inquiry has categories" do
      before do
        @inquiry.categories << phv_category
        @inquiry.categories << gkv_category
        @inquiry.save
        described_class.group_inquiries([@inquiry])
      end

      it "keeps the original inquiry" do
        expect(mandate.inquiries.count).to eq(1)
      end

      it "does not add a subcompany to it" do
        expect(@inquiry.reload.subcompany).to be_nil
      end
    end
  end

  it "keeps the inquiry categories from original inquiry and attach them to the new inquiries" do
    @inquiry.categories << phv_category
    @inquiry.save
    original_inquiry_category = InquiryCategory.last
    described_class.group_inquiries([@inquiry])
    expect(InquiryCategory.count).to eq(1)
    expect(InquiryCategory.last.id).to eq(original_inquiry_category.id)
  end

  it "removes the mapped categories from original inquiry" do
    @inquiry.categories << phv_category
    @inquiry.categories << gkv_category
    @inquiry.categories << category_without_subcompany
    @inquiry.save
    described_class.group_inquiries([@inquiry])
    expect(@inquiry.reload.categories.count).to eq(1)
  end

  it "groups the categories that belong to the same subcompany in one inquiry" do
    same_phv_vertical_category = create(:category, vertical: vertical_1)
    @inquiry.categories << phv_category
    @inquiry.categories << same_phv_vertical_category
    @inquiry.save
    described_class.group_inquiries([@inquiry])
    expect(mandate.inquiries.count).to eq(1)
    expect(mandate.inquiries.first.subcompany_id).to eq(allianz_phv_subcompany.id)
  end

  it "creates the inquiries in the same state of the original inquiry" do
    @inquiry.categories << phv_category
    @inquiry.state = :pending
    @inquiry.save
    described_class.group_inquiries([@inquiry])
    expect(mandate.inquiries.count).to eq(1)
    expect(mandate.inquiries.first.state).to eq(@inquiry.state)
  end
end
