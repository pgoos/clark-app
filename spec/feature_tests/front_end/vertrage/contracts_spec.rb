require "rails_helper"
require "./spec/support/features/page_objects/ember/manager/contracts_page"
require "./spec/support/features/page_objects/ember/mandate-funnel/select-category/category_page"
require "./spec/support/features/page_objects/ember/mandate-funnel/select-category/company_page"
require "./spec/support/features/page_objects/ember/rate-us/page"
RSpec.describe "Contracts", :browser, type: :feature, js: true do

  let(:locale) { I18n.locale }

  # Page objects
  let(:contracts_page) { ContractsPage.new }
  let(:cockpit_page) { ContractsCockpit.new }
  let(:select_category_page) { SelectCategoryPage.new }
  let(:select_company_page) { SelectCompanyPage.new }

  let!(:bu_category) { create(:bu_category) }

  let!(:user) do
    user = create(:user, confirmation_sent_at: 2.days.ago, mandate: create(:mandate))
    user.mandate.info["wizard_steps"] = ["profiling", "targeting", "confirming"]
    user.mandate.signature = create(:signature)
    user.mandate.confirmed_at = DateTime.current
    user.mandate.tos_accepted_at = DateTime.current
    # In creation so we don't get the add more insurances modal
    user.mandate.state = :in_creation
    # so they do not get retirement CTA's
    user.mandate.birthdate            =  Time.zone.now - 70.years
    user
  end

  context "with no categories in manager" do
    before do
      allow_any_instance_of(Mandate).to receive(:done_with_demandcheck?).and_return(true)
    end

    context "and an inquiry with and without a category" do
      let!(:inquiry_category) { create(:inquiry_category, category: bu_category) }
      let!(:inq_with_cat) { create(:inquiry, inquiry_categories: [inquiry_category], mandate: user.mandate) }
      let!(:inq_without_cat) { create(:inquiry, inquiry_categories: [], mandate: user.mandate) }

      before do
        login_as(user, scope: :user)
        contracts_page.visit_page
        contracts_page.expect_skeleton_gone
      end

      it "shows both cards" do
        cockpit_page.see_inquiry(inq_with_cat)
        cockpit_page.see_inquiry(inq_without_cat)
      end
    end

    context "and a product" do
      let!(:simple_product) { create(:product, mandate: user.mandate) }

      before do
        login_as(user, scope: :user)
        contracts_page.visit_page
        contracts_page.expect_skeleton_gone
      end

      it "shows the product card and uses the categroy sub resource" do
        cockpit_page.see_product_with_product(simple_product)
      end
    end
  end

  context "not done the demand check" do
    before do
      allow_any_instance_of(Mandate).to receive(:done_with_demandcheck?).and_return(false)
      login_as(user, scope: :user)
      contracts_page.visit_page
      contracts_page.expect_skeleton_gone
    end

    it "should show empty rings with do demand check CTA" do
      contracts_page.expect_do_demandcheck_state
      contracts_page.expect_demandcheck_cta_to_work
    end
  end

  context "with some recommendations" do
    let!(:recommendation_health) { create(:recommendation, mandate: user.mandate, category: create(:category, life_aspect: 'health')) }
    let!(:recommendation_things) { create(:recommendation, mandate: user.mandate, category: create(:category, life_aspect: 'things')) }
    let!(:recommendation_retirement) { create(:recommendation, mandate: user.mandate, category: create(:category, life_aspect: 'retirement')) }

    context "done demandcheck" do
      let!(:questionnaire) { create(:custom_questionnaire, identifier: "NhTVW2") }

      before do
        allow_any_instance_of(Mandate).to receive(:done_with_demandcheck?).and_return(true)
      end

      context "testing bu modal" do
        before do
          login_as(user, scope: :user)
          contracts_page.visit_page
          contracts_page.expect_skeleton_gone
        end

        it "should have a functional add bu modal" do
          contracts_page.expect_bu_modal_not_present
        end

      end

      context "with a bu category inquiry" do
        let!(:inquiry_category) { create(:inquiry_category, category: bu_category) }
        let!(:bu_inq) { create(:inquiry, inquiry_categories: [inquiry_category], mandate: user.mandate) }

        # placeholder product
        let!(:placeholder) { create(:recommendation, is_mandatory: true, mandate: user.mandate) }

        context "but cannot see totals" do

          before do
            login_as(user, scope: :user)
            contracts_page.visit_page
            contracts_page.expect_skeleton_gone
          end

          it "should show the rings with the correct amout of segments, and my score only. and add insurance should work" do
            contracts_page.expect_score_but_no_totals
          end
        end

        context "and can see the totals" do
          let!(:product_one) { create(:product, mandate: user.mandate) }
          let!(:product_two) { create(:product, mandate: user.mandate) }

          before do
            login_as(user, scope: :user)
            contracts_page.visit_page
            contracts_page.expect_skeleton_gone
          end

          it "should show my rings, show my score and show the monthly and anually totals" do
            contracts_page.expect_score_and_totals
          end
        end

      end

    end
  end

  context "IBAN notifications" do

    context "as an ING-Diba user" do
      let!(:user) {
        user = create(:user, source_data: {"adjust": {"network": "ing-diba"}}, mandate: create(:mandate))
        user.mandate.info["wizard_steps"] = ["targeting", "profiling", "confirming"]
        user.mandate.signature = create(:signature)
        user.mandate.confirmed_at = DateTime.current
        user.mandate.tos_accepted_at = DateTime.current
        user.mandate.state  = :in_creation
        user.mandate.save!
        user
      }

      let!(:sample_inquiry) { create(:inquiry, mandate: user.mandate)}


      context "who has submitted an IBAN" do
        before(:each) do
          user.mandate.iban = "FR1420041010050500013M02606"
          user.mandate.save!
          login_as(user, scope: :user)
        end

        it "I should not see the IBAN notification" do
          contracts_page.visit_page
          contracts_page.expect_skeleton_gone
          contracts_page.expect_no_notification
        end
      end

      context "who has not submitted an IBAN" do
        context "and has not seen the notification" do
          before(:each) do
            login_as(user, scope: :user)
          end
          it "I should see the IBAN notification" do
            contracts_page.visit_page
            contracts_page.expect_skeleton_gone

            # Make sure the notification is there
            contracts_page.expect_notification

            # and that clicking it takes you to the mandate iban page
            contracts_page.navigate_click(".manager__notification__text a", "iban")
          end
        end
        context "and has seen the IBAN notification" do
          before(:each) do
            login_as(user, scope: :user)
            contracts_page.visit_page
            contracts_page.set_seen_iban_notification
            contracts_page.refresh_page_for_cookie_changes
            contracts_page.expect_skeleton_gone
          end
          it "I should not see the IBAN notification" do
            contracts_page.expect_no_notification
          end
        end
      end
    end

    context "as an Primoco user" do
      let!(:user) {
        user = create(:user, source_data: {"adjust": {"network": "primoco"}}, mandate: create(:mandate))
        user.mandate = contracts_page.get_confirmed_user_or_lead(user)
        user
      }

      let!(:sample_inquiry) { create(:inquiry, mandate: user.mandate)}


      context "who has submitted an IBAN" do
        before(:each) do
          user.mandate.iban = "FR1420041010050500013M02606"
          user.mandate.save!
          login_as(user, scope: :user)
          contracts_page.visit_page
          contracts_page.expect_skeleton_gone
        end

        it "I should not see the IBAN notification" do
          contracts_page.expect_no_notification
        end
      end

      context "who has not submitted an IBAN" do
        context "and has not seen the notification" do
          before(:each) do
            login_as(user, scope: :user)
          end
          it "I should see the IBAN notification" do
            contracts_page.visit_page
            contracts_page.expect_skeleton_gone

            # Make sure the notification is there
            contracts_page.expect_notification

            # and that clicking it takes you to the mandate iban page
            contracts_page.navigate_click(".manager__notification__text a", "iban")
          end
        end
        context "and has seen the IBAN notification" do
          before(:each) do
            login_as(user, scope: :user)
            contracts_page.visit_page
            contracts_page.set_seen_iban_notification
            contracts_page.refresh_page_for_cookie_changes
            contracts_page.expect_skeleton_gone
          end
          it "I should not see the IBAN notification" do
            contracts_page.expect_no_notification
          end
        end
      end
    end

    context "as an Assona user" do
      let!(:user) {
        user = create(:user, source_data: {"adjust": {"network": "assona"}}, mandate: create(:mandate))
        user.mandate.info["wizard_steps"] = ["targeting", "profiling", "confirming"]
        user.mandate.signature = create(:signature)
        user.mandate.confirmed_at = DateTime.current
        user.mandate.tos_accepted_at = DateTime.current
        user.mandate.state  = :in_creation
        user.mandate.save!
        user
      }

      let!(:sample_inquiry) { create(:inquiry, mandate: user.mandate)}


      context "who has submitted an IBAN" do
        before(:each) do
          user.mandate.iban = "FR1420041010050500013M02606"
          user.mandate.save!
          login_as(user, scope: :user)
          contracts_page.visit_page
          contracts_page.expect_skeleton_gone
        end

        it "I should not see the IBAN notification" do
          contracts_page.expect_no_notification
        end
      end

      context "who has not submitted an IBAN" do
        context "and has not seen the notification" do
          before(:each) do
            login_as(user, scope: :user)
          end
          it "I should see the IBAN notification" do
            contracts_page.visit_page
            contracts_page.expect_skeleton_gone

            # Make sure the notification is there
            contracts_page.expect_notification
            # and that clicking it takes you to the mandate iban page
            contracts_page.navigate_click(".manager__notification__text a", "iban")
          end
        end
        context "and has seen the IBAN notification" do
          before(:each) do
            login_as(user, scope: :user)
            contracts_page.visit_page
            contracts_page.set_seen_iban_notification
            contracts_page.refresh_page_for_cookie_changes
            contracts_page.expect_skeleton_gone
          end
          it "I should not see the IBAN notification" do
            contracts_page.expect_no_notification
          end
        end
      end

      context "product add message" do

        before do
          login_as(user, scope: :user)
          contracts_page.visit_page
        end

        it "should see the popup" do
          contracts_page.expect_skeleton_gone
          contracts_page.expect_product_add_notification
        end

        it "should not see the popup" do
          contracts_page.set_seen_product_add_notification
          contracts_page.refresh_page_for_cookie_changes
          contracts_page.expect_skeleton_gone
          contracts_page.expect_no_product_add_notification
        end

      end
    end


    context "as an Finanzblick user" do
      let!(:user) {
        user = create(:user, source_data: {"adjust": {"network": "finanzblick"}},
                                  mandate: create(:mandate))
        user.mandate.info["wizard_steps"] = ["targeting", "profiling", "confirming"]
        user.mandate.signature = create(:signature)
        user.mandate.confirmed_at = DateTime.current
        user.mandate.tos_accepted_at = DateTime.current
        user.mandate.state  = :in_creation
        user.mandate.save!
        user
      }

      let!(:sample_inquiry) { create(:inquiry, mandate: user.mandate)}

      context "who has submitted an IBAN" do
        before(:each) do
          user.mandate.iban = "FR1420041010050500013M02606"
          user.mandate.save!
          login_as(user, scope: :user)
          contracts_page.visit_page
        end

        it "I should not see the IBAN notification" do
          contracts_page.expect_skeleton_gone
          contracts_page.expect_no_notification
        end
      end

      context "who has not submitted an IBAN" do
        context "and has not seen the notification" do
          before(:each) do
            login_as(user, scope: :user)
          end
          it "I should see the IBAN notification" do
            contracts_page.visit_page
            contracts_page.expect_skeleton_gone

            # Make sure the notification is there
            contracts_page.expect_notification

            # and that clicking it takes you to the mandate iban page
            contracts_page.navigate_click(".manager__notification__text a", "iban")
          end
        end
        context "and has seen the IBAN notification" do
          before(:each) do
            login_as(user, scope: :user)
            contracts_page.visit_page
            contracts_page.set_seen_iban_notification
            contracts_page.refresh_page_for_cookie_changes
            contracts_page.expect_skeleton_gone
          end
          it "I should not see the IBAN notification" do
            contracts_page.expect_no_notification
          end
        end
      end
    end
  end

  context "Miles and More customer" do
    context "as an Assona user" do
      let!(:user) {
        user = create(:user, source_data: {"adjust": {"network": "mam"}}, mandate: create(:mandate))
        user.mandate.info["wizard_steps"] = ["targeting", "profiling", "confirming"]
        user.mandate.signature = create(:signature)
        user.mandate.confirmed_at = DateTime.current
        user.mandate.tos_accepted_at = DateTime.current
        user.mandate.state  = :in_creation
        user.mandate.save!
        user
      }

      let!(:sample_inquiry) { create(:inquiry, mandate: user.mandate)}

      context "mam notification" do

        before do
          login_as(user, scope: :user)
          contracts_page.visit_page
        end

        it "should see the popup" do
          contracts_page.expect_skeleton_gone
          contracts_page.expect_notification
        end

        it "should navigate to mam page" do
          contracts_page.expect_skeleton_gone
          contracts_page.navigate_click(".manager__notification__mam__cta", "mam")
        end
      end

      context "mam notification" do
        it "should not see the popup" do
          contracts_page.visit_page
          contracts_page.set_seen_mam_notification
          contracts_page.refresh_page_for_cookie_changes
          contracts_page.expect_no_notification
        end
      end
    end
  end
end
