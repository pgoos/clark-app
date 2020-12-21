# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminPerformanceClassification, type: :model do
  subject { admin_performance_classification }

  let(:admin_performance_classification) do
    build(:admin_performance_classification)
  end

  it { is_expected.to be_valid }

  it { is_expected.to validate_uniqueness_of(:admin_id).scoped_to(:category_id) }
  it { is_expected.to validate_presence_of(:level) }

  describe "#performance_level_changed" do
    let(:admin) { create(:admin, role: create(:role)) }
    let(:category) { create(:category) }

    let(:performance_classification) do
      build :admin_performance_classification, admin: admin, category: category, level: "a"
    end

    it "create entity triggers method via callback" do
      expect { admin_performance_classification.save }
        .to broadcast(:performance_level_changed, admin_performance_classification)
    end

    it "update entity triggers method via callback" do
      admin_performance_classification.save

      expect { admin_performance_classification.update(level: "c") }
        .to broadcast(:performance_level_changed, admin_performance_classification)
    end

    it "delete entity does not trigger method via callback" do
      admin_performance_classification.save

      expect { admin_performance_classification.destroy }
        .not_to broadcast(:performance_level_changed, admin_performance_classification)
    end
  end
end
