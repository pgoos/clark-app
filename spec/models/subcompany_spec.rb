# == Schema Information
#
# Table name: subcompanies
#
#  id                 :integer          not null, primary key
#  company_id         :integer
#  ff_ident           :string
#  bafin_id           :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  name               :string
#  pools              :string           default([]), is an Array
#  info               :hstore
#  softfair_ids       :integer          default([]), is an Array
#  uci                :string
#  principal          :boolean
#  qualitypool_ident  :string
#  ident              :string
#  metadata           :jsonb
#  revenue_generating :boolean          default(FALSE)
#

require  "rails_helper"

RSpec.describe Subcompany, type: :model do

  # Setup

  let(:subject) { FactoryBot.build(:subcompany) }

  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns
  it_behaves_like "an auditable model"
  it_behaves_like "an identifiable for name model"

  context "#order_email" do
    before { subject.valid? }

    context "subcompany has no order_email" do
      it "returns no error" do
        expect(subject.errors).to be_empty
      end
    end

    context "subcompany has invalid order_email" do
      let(:subject) { build(:subcompany, order_email: "invalid-email") }

      it "has error" do
        expect(subject.errors).not_to be_empty
      end

      it "has error on order_email field" do
        expect(subject.errors[:order_email]).not_to be_nil
      end
    end

    context "subcompany has valid order_email" do
      let(:subject) { build(:subcompany, :with_order_email) }

      it "returns no error" do
        expect(subject.errors).to be_empty
      end
    end
  end

  context "contact_type" do
    context "when subcompany has contact_type as direct_agreement" do
      let(:subject) { build(:subcompany, contact_type: "direct_agreement") }

      it "requires an order_email" do
        expect(subject.errors[:order]).not_to be_nil
      end
    end

    context "when company has contact type other than direct_agreement" do
      let(:subject) { build(:subcompany, contact_type: "quality_pool") }

      it "does not require an order_email" do
        expect(subject.errors).to be_empty
      end
    end
  end

  # State Machine
  # Scopes

  describe ".for_category" do
    let!(:category) { create(:category) }

    it "searches only for a subcompany matching the categories vertical" do
      subcompanies = Subcompany.all
      expect(subcompanies).to receive(:where).with({ verticals: { id: [category.vertical.id] } })
      subcompanies.for_category(category)
    end

    it "searches for SUHK as well, when vertical is KV" do
      subcompanies = Subcompany.all
      category.vertical.update_attributes(ident: "KV")
      suhk_vertical = create(:vertical, ident: "SUHK")

      expect(subcompanies).to receive(:where).with({ verticals: { id: [category.vertical.id, suhk_vertical.id] } })
      subcompanies.for_category(category)
    end
  end

  context ".not_in_any_pool" do
    let(:subcompany_no_pool) { create(:subcompany) }
    let(:subcompany_in_pool) { create(:subcompany, pools: ["fonds_finanz"]) }

    it "have subcompany if it is not in a pool" do
      expect(Subcompany.not_in_any_pool).not_to include(subcompany_in_pool)
    end

    it "does not have subcompany in pool" do
      expect(Subcompany.not_in_any_pool).to include(subcompany_no_pool)
    end
  end

  # Associations

  it { expect(subject).to belong_to(:company) }
  it { expect(subject).to have_and_belong_to_many(:verticals) }
  it { expect(subject).to have_many(:plans).dependent(:restrict_with_error) }

  # Nested Attributes
  # Validations

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:company) }

  describe "verticals validation" do
    context "with minimum length of one" do
      it "allows to assign only one vertical to subcompany" do
        subject.verticals = []
        subject.verticals << build(:vertical)
        expect(subject).to be_valid
      end
    end

    context "with maximum length" do
      context "when only one vertical setting is turned on" do
        before { allow(Settings).to receive_message_chain("admin.subcompany.allow_only_one_vertical").and_return true }

        it "does not allow to assign more than one vertical to subcompany" do
          subject.verticals = []
          2.times { subject.verticals << build(:vertical) }
          expect(subject).not_to be_valid
        end
      end

      context "when only one vertical setting is turned off" do
        before { allow(Settings).to receive_message_chain("admin.subcompany.allow_only_one_vertical").and_return false }

        it "allows to assign more than one vertical to subcompany" do
          subject.verticals = []
          2.times { subject.verticals << build(:vertical) }
          expect(subject).to be_valid
        end
      end
    end
  end

  context  "unique creditor identifier (uci)" do
    it  "validates the uci country code (for now only DE, AT and GB are ok)" do
      subject.uci =  "DE98ZZZ09999999999"
      expect(subject).to be_valid
      subject.uci =  "AA41ZZZ09999999999"
      expect(subject).to_not be_valid
      expect(subject.errors[:uci]).to include( "Gläubiger-Identifikationsnummer ist nicht korrekt!")
    end

    it  "should be invalid, if the uci checksum is wrong" do
      subject.uci =  "DE97ZZZ09999999999"
      expect(subject).to_not be_valid
      expect(subject.errors[:uci]).to include( "Gläubiger-Identifikationsnummer ist nicht korrekt!")
    end

    it  "should be invalid, if the checksum is wrong for a different german uci" do
      subject.uci =  "DE16ZZZ00000031285"
      expect(subject).to_not be_valid
      expect(subject.errors[:uci]).to include( "Gläubiger-Identifikationsnummer ist nicht korrekt!")
    end

    it  "should validate a kind of minimum length" do
      subject.uci =  "DE00ZZZ0"
      expect(subject).to_not be_valid
      expect(subject.errors[:uci]).to include( "Gläubiger-Identifikationsnummer ist nicht korrekt!")
    end
  end

  it  "validates presence of ff_ident for FondsFinanz" do
    subject.pools << Subcompany::POOL_FONDS_FINANZ
    expect(subject).to validate_presence_of(:ff_ident)
  end

  it  "validates presence of bafin_id for QualityPool (when qualitypool_ident is nil)" do
    subject.pools << Subcompany::POOL_QUALITY_POOL
    subject.qualitypool_ident = nil
    expect(subject).to validate_presence_of(:bafin_id)
  end

  it  "validates presence of qualitypool_ident for QualityPool (when bafin_id is nil)" do
    subject.pools << Subcompany::POOL_QUALITY_POOL
    subject.bafin_id = nil
    expect(subject).to validate_presence_of(:qualitypool_ident)
  end

  it "validates inclusion of country_code" do
    subject.update(verticals: [])
    expect(subject).to validate_inclusion_of(:country_code).in_array(ISO3166::Country.codes)
  end
  # Callbacks
  # Instance Methods

  it  "does not store empty softfair ids from string" do
    subject.softfair_ids =  "12,13,,14,15"
    expect(subject.softfair_ids).to match_array([12, 13, 14, 15])
  end

  it  "does not store empty pools from array" do
    subject.pools = [ "quality_pool",  "", nil,  "fonds_finanz"]
    expect(subject.pools).to match_array([ "quality_pool",  "fonds_finanz"])
  end

  context "#gkv?" do
    it "returns false for an arbitrary company related" do
      subcompany = FactoryBot.build_stubbed(:subcompany)
      expect(subcompany).not_to be_gkv
    end

    it "retunrs true for a gkv company related" do
      subcompany = FactoryBot.build_stubbed(:subcompany_gkv)
      expect(subcompany).to be_gkv
    end
  end

  context "#formatted_b2b_contact_info" do
    subject { build_stubbed(:subcompany) }

    it "returns the correct contact info" do
      expect(subject.formatted_b2b_contact_info).to eq nil
      subject.b2b_contact_info = "street\nplz street"
      expect(subject.formatted_b2b_contact_info.first).to eq "street"
      expect(subject.formatted_b2b_contact_info.second).to eq "plz street"

      subject.b2b_contact_info = "street\r\nplz street"
      expect(subject.formatted_b2b_contact_info.first).to eq "street"
      expect(subject.formatted_b2b_contact_info.second).to eq "plz street"
    end
  end

  # Class Methods

  context "#id_for_ident" do
    it "should return nil, if the object is not found" do
      expect(described_class.id_for_ident("unknown_ident")).to be_nil
    end

    it "should return the id of the subcompany, if found for the ident" do
      subcompany = create(:subcompany)
      expect(Subcompany.id_for_ident(subcompany.ident)).to eq(subcompany.id)
    end
  end
end
