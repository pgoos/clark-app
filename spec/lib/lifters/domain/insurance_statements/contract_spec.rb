# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::InsuranceStatements::Contract do
  # TODO: Enable this after rebase
  # include_context "ensure locale is de"

  let(:mandate) { create(:mandate) }

  let(:things_category) { create(:category, name: "Things", life_aspect: "things") }
  let(:health_category) { create(:category, name: "Health", life_aspect: "health") }
  let(:retirement_category) { create(:category, name: "Retirement", life_aspect: "retirement") }

  let(:cockpit) { Domain::ContractOverview::Cockpit.new(mandate) }

  describe ".all" do
    subject { described_class.all(cockpit) }

    context "no products or inquiries" do
      it "should return an empty array" do
        expect(subject).to eq []
      end
    end

    context "with products" do
      before do
        create(:product, mandate:        mandate,
                                     category:       things_category,
                                     premium_price:  Money.new(10_000, "EUR"),
                                     premium_period: "year")
        create(:product, mandate:        mandate,
                                     category:       health_category,
                                     premium_price:  Money.new(20_000, "EUR"),
                                     premium_period: "month")
      end

      context "product category is gkv" do
        before do
          create(:product_gkv, mandate: mandate)
        end

        describe "#optimisation_amount" do
          subject { described_class.all(cockpit).map(&:optimisation_amount) }

          it "should return an empty string" do
            expect(subject).to include("")
          end
        end
      end

      describe "#life_aspect" do
        subject { described_class.all(cockpit).map(&:life_aspect_translated) }

        it "should return the translated life aspect text" do
          expect(subject).to match_array(["Gesundheit & Existenz", "Besitz & Eigentum"])
        end
      end

      describe "#category_name" do
        subject { described_class.all(cockpit).map(&:category_name) }

        it "should return the category names" do
          expect(subject).to match_array(%w[Health Things])
        end
      end

      describe "#category_ident" do
        subject { described_class.all(cockpit).map(&:category_ident) }

        it "returns the category ident" do
          expect(subject).to match_array([things_category.ident, health_category.ident])
        end
      end

      describe "#advice" do
        it "should be implemented"
      end

      describe "#optimisation_period" do
        subject { described_class.all(cockpit).map(&:optimisation_period) }

        it "should be premium period of the product" do
          expect(subject).to match_array(["pro Jahr", "pro Monat"])
        end

        context "optimisation state is salary" do
          it "should return translated salary text" do
            allow_any_instance_of(Product).to receive(:premium_period).and_return("none")
            allow_any_instance_of(Product).to receive(:premium_state).and_return("salary")

            expect(subject).to match_array(["vom Gehalt", "vom Gehalt"])
          end
        end
      end

      describe "#optimisation_amount" do
        subject { described_class.all(cockpit).map(&:optimisation_amount) }

        it "should be premium price of the product" do
          expect(subject).to match_array(["100,00 €", "200,00 €"])
        end
      end
    end

    context "with inquiries" do
      before do
        inquiry1 = create(:inquiry, :accepted, mandate: mandate)
        inquiry2 = create(:inquiry, :accepted, mandate: mandate)

        create(:inquiry_category, category: things_category,
                                              inquiry:  inquiry1)
        create(:inquiry_category, category: health_category,
                                              inquiry:  inquiry2)
      end

      describe "#life_aspect" do
        subject { described_class.all(cockpit).map(&:life_aspect_translated) }

        it "should return the translated life aspect text" do
          expect(subject).to match_array(["Gesundheit & Existenz", "Besitz & Eigentum"])
        end
      end

      describe "#category_name" do
        subject { described_class.all(cockpit).map(&:category_name) }

        it "should return the category names" do
          expect(subject).to match_array(%w[Health Things])
        end
      end

      describe "#advice" do
        it "should be implemented"
      end

      context "optimisation information" do
        %i[optimisation_amount optimisation_period].each do |section|
          describe "##{section}" do
            subject { described_class.all(cockpit).map(&section) }

            it "should be an empty string" do
              expect(subject).to match_array(["", ""])
            end
          end
        end
      end
    end

    context "inquiries and products" do
      before do
        inquiry1 = create(:inquiry, :accepted, mandate: mandate)
        create(:inquiry_category, category: health_category,
                                              inquiry:  inquiry1)
        create(:product, mandate:        mandate,
                                     category:       things_category,
                                     premium_price:  Money.new(10_000, "EUR"),
                                     premium_period: "year")
      end

      it "should include both products and inquiries" do
        expect(subject.size).to be >= 2
      end
    end
  end
end
