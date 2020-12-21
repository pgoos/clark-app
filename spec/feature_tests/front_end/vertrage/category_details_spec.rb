require 'rails_helper'
require './spec/support/features/page_objects/ember/manager/category_details_page'

RSpec.describe "Category Details", :browser, type: :feature, js: true do
  let(:locale) { I18n.locale }
  let(:details_page) { CategoryDetailsPage.new }

  # Create a user that has done all the steps
  let(:user) do
    user = create(:user, confirmation_sent_at: 2.days.ago, mandate: create(:mandate))
    user.mandate.info['wizard_steps'] = ['profiling', 'targeting', 'confirming']
    user.mandate.signature = create(:signature)
    # Need gender for automated gkv
    user.mandate.gender = 'male'
    user.mandate.confirmed_at = DateTime.current
    user.mandate.tos_accepted_at = DateTime.current
    user.mandate.state = :in_creation
    user.mandate.complete!
    user
  end

  context 'checking a simple category' do
    let!(:category) { create(:category, ident: "1d643477") }

    before do
      login_as(user, scope: :user)
      details_page.visit_page(category.id)
    end

    it 'should function as expected' do
      details_page.expect_standard_functionality(category)
      details_page.expect_quality_standards
      details_page.expect_clark_service
    end

  end

  context 'with not enough cover benchmark, and a questionnaire' do
    let!(:questionnaire) { create(:questionnaire) }
    let!(:category) do
      create(:category,
        questionnaire: questionnaire,
        ident: "7619902c",
        cover_benchmark: 5
      )
    end

    before do
      login_as(user, scope: :user)
      details_page.visit_page(category.id)
    end

    it 'should function as expected' do
      # No map as low cover benchmark < 10
      details_page.expect_no_map
      # Has a linked questionnaire
      details_page.expect_questionnaire_button
      # Shows the quality standards for non-gkv
      details_page.expect_no_compliance_text
      # Navigates to the correct category details page
      details_page.expect_navigated_to_correct_questionnaire(questionnaire.identifier)
    end
  end

  context "on a gkv offer details page" do
    # make sure we have a cat with quality standards (GKV)
    let!(:questionnaire) { create(:questionnaire) }
    let!(:category) { create(:category, questionnaire: questionnaire, ident: "3659e48a") }

    before do
      category.update(simple_checkout: true)
      category.update(life_aspect: "things")
      login_as(user, scope: :user)
      details_page.visit_page(category.id)
    end

    it "Should show the compliance text" do
      details_page.expect_compliance_text
    end
  end
end
