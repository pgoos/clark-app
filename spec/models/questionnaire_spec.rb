# frozen_string_literal: true

# == Schema Information
#
# Table name: questionnaires
#
#  id                 :integer          not null, primary key
#  identifier         :string
#  created_at         :datetime
#  updated_at         :datetime
#  category_id        :integer
#  questionnaire_type :string           default("typeform"), not null
#  name               :string
#  description        :text
#  internal_name      :string
#

require "rails_helper"

RSpec.describe Questionnaire, type: :model do
  # Settings
  # Constants
  # Attribute Settings
  # Plugins
  # Concerns

  it_behaves_like "an auditable model"

  # State Machine
  # Scopes
  context "scopes" do
    let!(:category) { create(:active_category) }
    let!(:questionnaire1) { create(:questionnaire, category: category) }
    let!(:questionnaire2) { create(:questionnaire, category: category) }

    context "active" do
      before { category.update(questionnaire_id: questionnaire1.id) }

      context "associate category is inactive" do
        it "should not return even though category is using the questionnaire" do
          category.update(state: "inactive")
          expect(Questionnaire.active.pluck(:id)).to eq([])
        end
      end

      context "associate category is active" do
        it "should return if category is using the questionnaire" do
          expect(Questionnaire.active.pluck(:id)).to eq([questionnaire1.id])
        end
      end
    end

    context "inactive" do
      let!(:category2) { create(:active_category) }

      before { category2.update(questionnaire_id: questionnaire1.id) }

      it "should return only inactive questionnaires" do
        expect(Questionnaire.inactive.pluck(:id)).to match_array([questionnaire1.id, questionnaire2.id])
      end
    end
  end

  # Delegates

  it { is_expected.to delegate_method(:margin_level).to(:category) }

  # Associations

  it { expect(subject).to have_many(:responses) }
  it { expect(subject).to belong_to(:category) }
  it { expect(subject).to have_many(:questionings) }
  it { expect(subject).to have_many(:questions) }

  # Nested Attributes
  # Validations

  it { expect(subject).to validate_uniqueness_of(:identifier) }

  # Callbacks
  # Instance Methods

  describe "#active?" do
    let(:questionnaire) { create(:questionnaire, category: category) }

    context "category is active" do
      let(:category) { create(:active_category) }

      it "should return true if associate category using this questionnaire" do
        category.update(questionnaire_id: questionnaire.id)
        expect(questionnaire.reload.active?).to eq(true)
      end

      it "should return false if associate category is not using this questionnaire" do
        expect(questionnaire.active?).to eq(false)
      end
    end

    context "category is active" do
      let(:category) { create(:category, state: "inactive") }

      it "should return false even though associate category using this questionnaire" do
        category.update(questionnaire_id: questionnaire.id)
        expect(questionnaire.reload.active?).to eq(false)
      end

      it "should return false if associate category is not using this questionnaire" do
        expect(questionnaire.active?).to eq(false)
      end
    end
  end

  context "with name method" do
    it "returns the name if a name is set" do
      expect(Questionnaire.new(name: "formular").name).to eq("formular")
    end

    it "returns a generated name if the name is empty" do
      expect(Questionnaire.new(name: nil, questionnaire_type: "typeform", identifier: "abc123").name)
        .to eq("Typeform abc123")
    end
  end

  context "with description" do
    it "returns the description if set" do
      expect(Questionnaire.new(description: "formular").description).to eq("formular")
    end

    it "returns the name as description if description is empty" do
      expect(Questionnaire.new(name: "formular").description).to eq("formular")
    end
  end
end
