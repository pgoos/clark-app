# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::BaseHelper do
  describe "#mandate_from_parent" do
    let(:mandate) { build_stubbed(:mandate) }
    let(:opportunity) { build_stubbed(:opportunity, mandate: mandate) }
    let(:inquiry) { build_stubbed(:inquiry, mandate: mandate) }
    let(:product) { build_stubbed(:product, mandate: mandate) }
    let(:user) { build_stubbed(:user, mandate: mandate) }

    it "shows the correct helper" do
      allow(helper).to receive(:current_parent).and_return(mandate)
      expect(helper.mandate_from_parent).to eq mandate
      allow(helper).to receive(:current_parent).and_return(inquiry)
      expect(helper.mandate_from_parent).to eq mandate
      allow(helper).to receive(:current_parent).and_return(opportunity)
      expect(helper.mandate_from_parent).to eq mandate
      allow(helper).to receive(:current_parent).and_return(product)
      expect(helper.mandate_from_parent).to eq mandate
      allow(helper).to receive(:current_parent).and_return(user)
      expect(helper.mandate_from_parent).to eq nil
    end
  end

  describe "#advice_template_replacements" do
    context "when it is related to additional contribution" do
      let(:company) { create(:company) }
      let(:product) { create(:product, company: company) }

      it "formats the number correctly" do
        text = "start \#{zusatzbeitrag} end"
        company.update!(national_health_insurance_premium_percentage: 1.35)
        new_text = helper.advice_template_replacements(text, product)
        expect(new_text).to eq "start 1,35 end"

        company.update!(national_health_insurance_premium_percentage: 1.2)
        product.reload
        new_text = helper.advice_template_replacements(text, product)
        expect(new_text).to eq "start 1,2 end"

        company.update!(national_health_insurance_premium_percentage: 1.456)
        product.reload
        new_text = helper.advice_template_replacements(text, product)
        expect(new_text).to eq "start 1,46 end"

        text = "start \#{zusatz} end"
        new_text = helper.advice_template_replacements(text, product)
        expect(new_text).to eq "start \#{zusatz} end"
      end
    end
  end

  describe "#call_types" do
    it "gets types correctly from phone_call class" do
      types = helper.call_types.map { |ind| ind[1] }
      expect(types).to eq Interaction::PhoneCall.call_types.values
    end

    it "is translated correctly according to localisation" do
      translations = helper.call_types.map { |ind| ind[0] }
      expect(translations).to eq I18n.t("admin.interactions.phone_call.type").values
    end
  end

  describe "#restricted_section_by_event" do
    let(:restricted_result) { "result of the block output" }
    let(:empty_result) { "" }
    let(:current_admin) { create :admin, role: role }
    let(:permitted_controller) { "admin/opportunities" }
    let(:permitted_event) { :cancel }

    context "admin is logged in" do
      before do
        allow_any_instance_of(described_class).to receive(:admin_signed_in?).and_return(true)
        allow_any_instance_of(described_class).to receive(:current_admin).and_return(current_admin)
      end

      context "permission exists" do
        let(:role) do
          create(:role,
                 permissions: Permission.where(controller: permitted_controller, action: permitted_event.to_s))
        end

        it "returns the restricted result" do
          result = helper.restricted_section_by_event(permitted_controller, permitted_event) { restricted_result }

          expect(result).to eq(restricted_result)
        end
      end

      context "permission does not exists" do
        let(:role) { create :role }

        it "does not return the restricted result" do
          result = helper.restricted_section_by_event(permitted_controller, permitted_event) { restricted_result }

          expect(result).to eq(empty_result)
        end
      end

      context "event is not setted in the modal" do
        let(:role) do
          create(:role,
                 permissions: Permission.where(controller: permitted_controller, action: permitted_event.to_s))
        end

        it "returns the restricted result" do
          result = helper.restricted_section_by_event(permitted_controller, nil) { restricted_result }

          expect(result).to eq(restricted_result)
        end
      end
    end

    context "admin is NOT logged in" do
      before do
        allow_any_instance_of(described_class).to receive(:admin_signed_in?).and_return(false)
      end

      context "permission exists" do
        let(:role) do
          create(:role,
                 permissions: Permission.where(controller: permitted_controller, action: permitted_event.to_s))
        end

        it "does not return the restricted result" do
          result = helper.restricted_section_by_event(permitted_controller, permitted_event) { restricted_result }

          expect(result).to eq(empty_result)
        end
      end

      context "permission does not exists" do
        let(:role) { create :role }

        it "does not return the restricted result" do
          result = helper.restricted_section_by_event(permitted_controller, permitted_event) { restricted_result }

          expect(result).to eq(empty_result)
        end
      end

      context "event is not setted in the modal" do
        let(:role) do
          create(:role,
                 permissions: Permission.where(controller: permitted_controller, action: permitted_event.to_s))
        end

        it "does not return the restricted result" do
          result = helper.restricted_section_by_event(permitted_controller, nil) { restricted_result }

          expect(result).to eq(empty_result)
        end
      end
    end
  end
end
