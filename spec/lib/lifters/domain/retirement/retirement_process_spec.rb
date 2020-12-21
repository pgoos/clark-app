# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Retirement::RetirementProcess do
  let(:mandate) { create(:mandate, state: :accepted) }

  context "Existing mandate" do
    before do
      create(:plan, :equity) # implies category creation
      create(:plan, :state) # implies category creation
      create(:category, :overall_personal)
      create(:category, :overall_corporate)
      create(:user, mandate: mandate)
    end

    context "without retirement products" do
      context ".mandate_equity_products" do
        it "returns 0 products" do
          expect(described_class.mandate_equity_products(mandate).count).to eq(0)
        end
      end

      context ".create_equity_product" do
        it "creates a new equity product" do
          expect_any_instance_of(Retirement::Product).to receive(:details_saved)
          product = described_class.create_equity_product(mandate, 1)
          retirement_product = product.retirement_product
          expect(retirement_product.type).to eq("Retirement::EquityProduct")
          expect(retirement_product.equity_today_cents).to eq(100)
        end
      end

      context ".product_setup_state_product" do
        it "creates a new state product" do
          product = described_class.product_setup_state_product(mandate)
          expect(product).to be_truthy
        end
      end

      context ".recommend_cockpit" do
        it "creates an empty cockpit" do
          cockpit = described_class.recommend_cockpit(mandate)
          expect(mandate.retirement_cockpit).to be_present
        end
      end
    end

    describe ".documents_to_be_completed" do
      context "with no documents" do
        it "should not return any documents" do
          expect(described_class.documents_to_be_completed).to be_empty
        end
      end

      context "with retirement documents" do
        let(:mandate) { create(:mandate) }
        let!(:retirement_document) do
          create(:document, :retirement_document, documentable: mandate)
        end
        let!(:other_document) do
          create(:document, documentable_type: "Mandate", documentable: mandate)
        end

        it "should return retirement documents" do
          result = described_class.documents_to_be_completed

          expect(result.to_a).to match_array([mandate])
          expect(result.first.documents).to match_array([retirement_document])
        end

        context 'with revoked mandate documents' do
          let(:revoked_mandate) { create(:mandate, :revoked) }
          let!(:revoked_mandate_retirement_document) do
            create(:document, :retirement_document, documentable: revoked_mandate)
          end
          let(:admin) { create(:admin) }

          it "should not include revoked mandates" do
            result = described_class.documents_to_be_completed(admin: admin)

            expect(result.to_a).to match_array([mandate])
          end

          context "admin with can_view_revoked_mandates? permission" do
            before do
              admin.permissions << create(:permission, :view_revoked_mandates)
            end

            it "should include revoked mandates" do
              result = described_class.documents_to_be_completed(admin: admin)

              expect(result.to_a).to match_array([mandate, revoked_mandate])
            end
          end
        end
      end
    end

    describe ".assign_retirement_documents_to_products" do
      let(:mandate) { create(:mandate) }
      let(:product) { described_class.create_state_product(mandate) }
      let(:retirement_document) do
        create(:document, :retirement_document, documentable: mandate)
      end

      it "should assign retirement documents from mandates to products" do
        id = retirement_document.id
        documents = described_class.documents_to_be_completed.first.documents
        described_class.assign_retirement_documents_to_products(documents, product)

        expect(described_class.documents_to_be_completed).to be_empty

        document = Document.find(id)
        expect(document.documentable_type).to eq("Product")
        expect(document.documentable_id).to eq(product.id)
      end
    end
  end

  context ".retirement_enabled?" do
    let(:product_with_equity) { create(:product, :retirement_equity_product) }

    it "identifies a product_with_equity as retirement_enabled" do
      expect(described_class.retirement_enabled?(product_with_equity)).to eq(true)
    end
  end

  context ".setup_retirement_product" do
    context "with a non retirement product" do
      let(:product) { create(:product) }

      it "adds no retirement product to a product with a non-retirement category" do
        described_class.setup_retirement_product(product)
        expect(product.retirement_product).to eq(nil)
      end
    end

    context "with a retirement product" do
      let(:product) { create(:product, :retirement_equity_category) }

      context "with an equity product" do
        it "adds an equity retirement product to a product with a equity category" do
          described_class.setup_retirement_product(product)
          expect(product.retirement_product).to be_truthy
        end
      end

      context "setup with a different type" do
        let(:personal_type) { described_class::TYPES_TO_CLASSNAMES[:personal] }

        before { described_class.setup_retirement_product(product) }

        it "should remove the retirement product and create a new one" do
          expect(product.retirement_product).to receive(:delete).and_call_original
          expect(product).to receive(:save!).at_least(:once).and_call_original
          product.retirement_product.type = personal_type
          described_class.setup_retirement_product(product)
        end

        it "should not remove the retirement product and return a Product" do
          expect(product.retirement_product).not_to receive(:delete)
          described_class.setup_retirement_product(product)
        end
      end

      context "same type and category" do
        it "should return the product without changing anything" do
          described_class.setup_retirement_product(product)
          expect(product.retirement_product).not_to receive(:delete)
          expect(product.retirement_product).not_to receive(:save!)
          described_class.setup_retirement_product(product)
        end
      end

      context "different type" do
        # Product is a kapitallebensversicherung(personal)
        let(:product) { create(:product, :retirement_overall_personal_product) }
        let(:other_ident) { Domain::Retirement::CategoryIdents::CATEGORY_IDENT_DIREKTVERSICHERUNG_CLASSIC }
        # Other category type is corporate
        let(:other_product_category) { create(:category, ident: other_ident) }
        let(:other_category_setup_data) do
          Domain::Retirement::CategoryIdents::RETIREMENT_ENABLED_CATEGORY_IDENTS[other_ident]
        end

        it "should remove the retirement and add a new one" do
          described_class.setup_retirement_product(product)
          other_retirement_category = other_category_setup_data[:category]
          product.category = other_product_category

          allow(product.retirement_product).to receive(:category)
            .and_return(other_retirement_category)

          expect(product.retirement_product).to receive(:delete)
          described_class.setup_retirement_product(product)
          expect(product.retirement_product).to be_present
          expect(product.retirement_product.category).to eq(other_retirement_category)
        end
      end

      context "setup with a different category within the same type" do
        # Product is a kapitallebensversicherung
        let(:product) { create(:product, :retirement_overall_personal_product) }
        let(:other_ident) { Domain::Retirement::CategoryIdents::CATEGORY_IDENT_PRIVATE_RENTENVERSICHERUNG }
        let(:other_product_category) { create(:category, ident: other_ident) }
        let(:other_category_setup_data) do
          Domain::Retirement::CategoryIdents::RETIREMENT_ENABLED_CATEGORY_IDENTS[other_ident]
        end

        it "should update the retirement product category" do
          other_retirement_category = other_category_setup_data[:category]
          product.retirement_product.category = other_retirement_category
          product.retirement_product.save!
          product.category = other_product_category
          described_class.setup_retirement_product(product)
          expect(product.retirement_product).to be_present
          expect(product.retirement_product.category).to eq(other_retirement_category)
        end
      end
    end
  end

  context ".retirement_setup_data" do
    let(:product) { instance_double("Product") }
    before do
      allow(product).to receive_message_chain(:category, :combo?).and_return(false)
    end

    context "with a non retirement product" do
      before do
        allow(product).to receive_message_chain("category.ident").and_return("foo")
      end

      it "returns empty setup data" do
        result = described_class.retirement_setup_data(product)
        expect(result).to be_nil
      end
    end

    context "with a non-combo retirement product (equity)" do
      before do
        allow(product).to receive_message_chain("category.ident")
          .and_return(Domain::Retirement::CategoryIdents::CATEGORY_IDENT_EQUITY)
      end

      it "returns the retirement relevant setup data" do
        result = described_class.retirement_setup_data(product)
        expect(result).to be_truthy
        expect(result[:type]).to eq(:equity)
        expect(result[:category]).to eq("vermoegen")
      end
    end

    context "with a combo retirement product" do
      before do
        allow(product).to receive_message_chain("category.ident").and_return("foo")
        allow(product).to receive_message_chain(:category, :combo?).and_return(true)
        allow(product).to receive_message_chain("category.included_categories.pluck")
          .and_return([Domain::Retirement::CategoryIdents::CATEGORY_IDENT_EQUITY, "nomatch"])
      end

      it "returns the retirement relevant setup data" do
        result = described_class.retirement_setup_data(product)
        expect(result).to be_truthy
        expect(result[:type]).to eq(:equity)
        expect(result[:category]).to eq("vermoegen")
      end
    end
  end

  context ".remove_retirement_product!" do
    let(:product_with_equity) { create(:product, :retirement_equity_product) }

    it "removes the retirement product" do
      expect(product_with_equity.retirement_product).to be_truthy
      described_class.remove_retirement_product!(product_with_equity)
      product_with_equity.reload
      expect(product_with_equity.retirement_product).to eq(nil)
    end
  end

  context "#all_retirement_category_idents", :integration do
    let(:overall_category_idents) { Domain::Retirement::CategoryIdents::OVERALL_CATEGORIES }

    let(:category_idents_personal) do
      cat_map = Domain::Retirement::CategoryIdents::RETIREMENT_ENABLED_CATEGORY_IDENTS.select do |_, attr|
        attr[:type] == :personal
      end
      cat_map.keys
    end
    let(:category_ids_personal) { [] }

    let(:category_idents_corporate) do
      cat_map = Domain::Retirement::CategoryIdents::RETIREMENT_ENABLED_CATEGORY_IDENTS.select do |_, attr|
        attr[:type] == :corporate
      end
      cat_map.keys
    end
    let(:category_ids_corporate) { [] }

    let(:umbrella_personal) do
      raise "called too early" if category_ids_personal.empty?
      create(
        :umbrella_category,
        :overall_personal,
        included_category_ids: category_ids_personal
      )
    end
    let(:umbrella_corporate) do
      raise "called too early" if category_ids_corporate.empty?
      create(
        :umbrella_category,
        :overall_corporate,
        included_category_ids: category_ids_corporate
      )
    end

    let(:concrete_category_idents) {
      Domain::Retirement::CategoryIdents::RETIREMENT_ENABLED_CATEGORY_IDENTS.keys.sort
    }

    before do
      category_idents_personal.each do |ident|
        category_ids_personal << create(:category, ident: ident).id
      end

      category_idents_corporate.each do |ident|
        category_ids_corporate << create(:category, ident: ident).id
      end

      create(:category, :equity)
      create(:category, :state)
    end

    it "should find all idents" do
      umbrella_personal
      umbrella_corporate
      expected_idents = (overall_category_idents + concrete_category_idents).sort
      expect(described_class.all_retirement_category_idents).to eq(expected_idents)
    end

    it "should not send anything to Sentry" do
      umbrella_personal
      umbrella_corporate
      expect(Raven).not_to receive(:capture_exception)
      described_class.all_retirement_category_idents
    end

    it "should find an additional ident, if a category got added later to the personal umbrella" do
      c_personal = create(:category)
      category_ids_personal << c_personal.id
      umbrella_personal
      expect(described_class.all_retirement_category_idents).to include(c_personal.ident)
    end

    it "should find an additional ident, if a category got added later to the corporate umbrella" do
      c_corporate = create(:category)
      category_ids_corporate << c_corporate.id
      umbrella_corporate
      expect(described_class.all_retirement_category_idents).to include(c_corporate.ident)
    end

    it "should send Ravens, if a categories got added later to the umbrellas" do
      c_personal = create(:category)
      category_ids_personal << c_personal.id

      c_corporate = create(:category)
      category_ids_corporate << c_corporate.id

      umbrella_personal
      umbrella_corporate

      expect(Raven).to receive(:capture_message).with(
        "Unknown retirement category ident: #{c_personal.ident}"
      )
      expect(Raven).to receive(:capture_message).with(
        "Unknown retirement category ident: #{c_corporate.ident}"
      )

      described_class.all_retirement_category_idents
    end
  end
end
