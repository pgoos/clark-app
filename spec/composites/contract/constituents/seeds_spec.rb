# frozen_string_literal: true

require "rails_helper"
require "composites/contract/constituents/seed"

RSpec.describe Contract::Constituents::Seed do
  subject(:seeds) { described_class.new }

  def check_result(result)
    expect(result.keys.sort).to eq(%i[contract_id customer_id].sort)
    contract_correctly_created(result[:contract_id])
    customer_created_correctly(result[:customer_id])
  end

  def result_has_normal_us_advised_instant(result)
    expect(result[:normal][:sold_by_us][:has_advice][:has_instant_advice]).to be_present
    check_result(result[:normal][:sold_by_us][:has_advice][:has_instant_advice])
  end

  def result_has_normal_us_advised_non_instant(result)
    expect(result[:normal][:sold_by_us][:has_advice][:has_no_instant_advice]).to be_present
    check_result(result[:normal][:sold_by_us][:has_advice][:has_no_instant_advice])
  end

  def result_has_normal_us_non_advised_instant(result)
    expect(result[:normal][:sold_by_us][:has_no_advice][:has_instant_advice]).to be_present
    check_result(result[:normal][:sold_by_us][:has_no_advice][:has_instant_advice])
  end

  def result_has_normal_us_non_advised_non_instant(result)
    expect(result[:normal][:sold_by_us][:has_no_advice][:has_no_instant_advice]).to be_present
    check_result(result[:normal][:sold_by_us][:has_no_advice][:has_no_instant_advice])
  end

  def result_has_normal_others_advised_instant(result)
    expect(result[:normal][:sold_by_others][:has_advice][:has_instant_advice]).to be_present
    check_result(result[:normal][:sold_by_others][:has_advice][:has_instant_advice])
  end

  def result_has_normal_others_advised_non_instant(result)
    expect(result[:normal][:sold_by_others][:has_advice][:has_no_instant_advice]).to be_present
    check_result(result[:normal][:sold_by_others][:has_advice][:has_no_instant_advice])
  end

  def result_has_normal_others_non_advised_instant(result)
    expect(result[:normal][:sold_by_others][:has_no_advice][:has_instant_advice]).to be_present
    check_result(result[:normal][:sold_by_others][:has_no_advice][:has_instant_advice])
  end

  def result_has_normal_others_non_advised_non_instant(result)
    expect(result[:normal][:sold_by_others][:has_no_advice][:has_no_instant_advice]).to be_present
    check_result(result[:normal][:sold_by_others][:has_no_advice][:has_no_instant_advice])
  end

  def result_has_gkv_us_advised_instant(result)
    expect(result[:gkv][:sold_by_us][:has_advice][:has_instant_advice]).to be_present
    check_result(result[:gkv][:sold_by_us][:has_advice][:has_instant_advice])
  end

  def result_has_gkv_us_advised_non_instant(result)
    expect(result[:gkv][:sold_by_us][:has_advice][:has_no_instant_advice]).to be_present
    check_result(result[:gkv][:sold_by_us][:has_advice][:has_no_instant_advice])
  end

  def result_has_gkv_us_non_advised_instant(result)
    expect(result[:gkv][:sold_by_us][:has_no_advice][:has_instant_advice]).to be_present
    check_result(result[:gkv][:sold_by_us][:has_no_advice][:has_instant_advice])
  end

  def result_has_gkv_us_non_advised_non_instant(result)
    expect(result[:gkv][:sold_by_us][:has_no_advice][:has_no_instant_advice]).to be_present
    check_result(result[:gkv][:sold_by_us][:has_no_advice][:has_no_instant_advice])
  end

  def result_has_gkv_others_advised_instant(result)
    expect(result[:gkv][:sold_by_others][:has_advice][:has_instant_advice]).to be_present
    check_result(result[:gkv][:sold_by_others][:has_advice][:has_instant_advice])
  end

  def result_has_gkv_others_advised_non_instant(result)
    expect(result[:gkv][:sold_by_others][:has_advice][:has_no_instant_advice]).to be_present
    check_result(result[:gkv][:sold_by_others][:has_advice][:has_no_instant_advice])
  end

  def result_has_gkv_others_non_advised_instant(result)
    expect(result[:gkv][:sold_by_others][:has_no_advice][:has_instant_advice]).to be_present
    check_result(result[:gkv][:sold_by_others][:has_no_advice][:has_instant_advice])
  end

  def result_has_gkv_others_non_advised_non_instant(result)
    expect(result[:gkv][:sold_by_others][:has_no_advice][:has_no_instant_advice]).to be_present
    check_result(result[:gkv][:sold_by_others][:has_no_advice][:has_no_instant_advice])
  end

  def contract_correctly_created(id)
    expect(Product.where(id: id)).to be_exist
  end

  def customer_created_correctly(id)
    expect(Mandate.where(id: id)).to be_exist
  end

  it "includes Utils::Seeder in included modules" do
    expect(seeds).to be_kind_of Utils::Seeder
  end

  describe "#seed_all", :integration do
    it "creates a single product-customer combination for each instant advice case" do
      result = seeds.seed_all
      result_has_normal_us_advised_instant(result)
      result_has_normal_us_advised_non_instant(result)
      result_has_normal_us_non_advised_instant(result)
      result_has_normal_us_non_advised_non_instant(result)
      result_has_normal_others_advised_instant(result)
      result_has_normal_others_advised_non_instant(result)
      result_has_normal_others_non_advised_instant(result)
      result_has_normal_others_non_advised_non_instant(result)
      result_has_gkv_us_advised_instant(result)
      result_has_gkv_us_advised_non_instant(result)
      result_has_gkv_us_non_advised_instant(result)
      result_has_gkv_us_non_advised_non_instant(result)
      result_has_gkv_others_advised_instant(result)
      result_has_gkv_others_advised_non_instant(result)
      result_has_gkv_others_non_advised_instant(result)
      result_has_gkv_others_non_advised_non_instant(result)
    end
  end

  describe "each case", :integration do
    context "normal product" do
      context "sold by us" do
        context "has advice" do
          context "has instant advice" do
            it "creates this case" do
              result = seeds.create_normal_sold_by_us_advised_instant
              result_has_normal_us_advised_instant(result)
            end
          end

          context "has no instant advice" do
            it "creates this case" do
              result = seeds.create_normal_sold_by_us_advised_non_instant
              result_has_normal_us_advised_non_instant(result)
            end
          end
        end

        context "has no advice" do
          context "has instant advice" do
            it "creates this case" do
              result = seeds.create_normal_sold_by_us_non_advised_instant
              result_has_normal_us_non_advised_instant(result)
            end
          end

          context "has no instant advice" do
            it "creates this case" do
              result = seeds.create_normal_sold_by_us_non_advised_non_instant
              result_has_normal_us_non_advised_non_instant(result)
            end
          end
        end
      end

      context "sold by others" do
        context "has advice" do
          context "has instant advice" do
            it "create that case" do
              result = seeds.create_normal_sold_by_others_advised_instant
              result_has_normal_others_advised_instant(result)
            end
          end

          context "has no instant advice" do
            it "create that case" do
              result = seeds.create_normal_sold_by_others_advised_non_instant
              result_has_normal_others_advised_non_instant(result)
            end
          end
        end

        context "has no advice" do
          context "has instant advice" do
            it "create that case" do
              result = seeds.create_normal_sold_by_others_non_advised_instant
              result_has_normal_others_non_advised_instant(result)
            end
          end

          context "has no instant advice" do
            it "create that case" do
              result = seeds.create_normal_sold_by_others_non_advised_non_instant
              result_has_normal_others_non_advised_non_instant(result)
            end
          end
        end
      end
    end

    context "gkv product" do
      context "sold by us" do
        context "has advice" do
          context "has instant advice" do
            it "create that case" do
              result = seeds.create_gkv_sold_by_us_advised_instant
              result_has_gkv_us_advised_instant(result)
            end
          end

          context "has no instant advice" do
            it "create that case" do
              result = seeds.create_gkv_sold_by_us_advised_non_instant
              result_has_gkv_us_advised_non_instant(result)
            end
          end
        end

        context "has no advice" do
          context "has instant advice" do
            it "create that case" do
              result = seeds.create_gkv_sold_by_us_non_advised_instant
              result_has_gkv_us_non_advised_instant(result)
            end
          end

          context "has no instant advice" do
            it "create that case" do
              result = seeds.create_gkv_sold_by_us_non_advised_non_instant
              result_has_gkv_us_non_advised_non_instant(result)
            end
          end
        end
      end

      context "sold by others" do
        context "has advice" do
          context "has instant advice" do
            it "create that case" do
              result = seeds.create_gkv_sold_by_others_advised_instant
              result_has_gkv_others_advised_instant(result)
            end
          end

          context "has no instant advice" do
            it "create that case" do
              result = seeds.create_gkv_sold_by_others_advised_non_instant
              result_has_gkv_others_advised_non_instant(result)
            end
          end
        end

        context "has no advice" do
          context "has instant advice" do
            it "create that case" do
              result = seeds.create_gkv_sold_by_others_non_advised_instant
              result_has_gkv_others_non_advised_instant(result)
            end
          end

          context "has no instant advice" do
            it "create that case" do
              result = seeds.create_gkv_sold_by_others_non_advised_non_instant
              result_has_gkv_others_non_advised_non_instant(result)
            end
          end
        end
      end
    end
  end
end
