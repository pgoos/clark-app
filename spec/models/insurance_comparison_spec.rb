# frozen_string_literal: true
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


require "rails_helper"

RSpec.describe InsuranceComparison, type: :model do
  subject { described_class.create(opportunity: opportunity) }

  let(:opportunity) { create(:opportunity, mandate: mandate, category: category) }
  let(:mandate) { create(:mandate) }
  let(:category) { create(:category) }

  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns

  it_behaves_like "an auditable model"
  it_behaves_like "a documentable"

  # Index
  # State Machine
  # Scopes
  # Associations

  it { expect(subject).to belong_to(:opportunity) }
  it { expect(subject).to belong_to(:mandate) }
  it { expect(subject).to belong_to(:category) }

  # Nested Attributes
  # Validations

  it { is_expected.to validate_presence_of(:opportunity) }

  # Callbacks

  context "before_validation" do
    let(:subject_before_validation) { described_class.new(opportunity: opportunity) }

    before do
      subject_before_validation.valid?
    end

    it "automatically sets the mandate" do
      expect(subject_before_validation.mandate_id).to eq(mandate.id)
    end

    it "automatically sets the category" do
      expect(subject_before_validation.category_id).to eq(category.id)
    end
  end

  # Delegates
  # Instance Methods

  context "request / response xml" do
    let(:request_xml) { dummy_xml }
    let(:response_xml) { dummy_xml }

    before do
      subject.documents.create!(
        asset:         Platform::StringFileStub.new("pre", "post", "xml", request_xml),
        document_type: DocumentType.comparison_request
      )
      subject.documents.create!(
        asset:         Platform::StringFileStub.new("pre", "post", "xml", response_xml),
        document_type: DocumentType.comparison_response
      )
    end

    it "should return the request" do
      expect(subject.comparison_request).to eq(request_xml)
    end

    it "should return the response" do
      expect(subject.comparison_response).to eq(response_xml)
    end
  end

  def dummy_xml
    <<EOX
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<!-- allways create a different dummy xml => #{rand} -->
</soap:Envelope>
EOX
  end
end
