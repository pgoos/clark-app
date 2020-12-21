require 'rails_helper'
require './spec/support/features/page_objects/ember/select_category/request_offer_page'

RSpec.describe 'SelectCategory', :timeout, :slow, :clark_context, :browser, type: :feature, js: true, skip: "excluded from nightly, review" do

  let(:locale) { I18n.locale }
  let(:request_offer_page) { RequestOfferPage.new }

  context 'user who has done everything' do

    let!(:user) do
      user = create(:user, mandate: create(:mandate))
      user.mandate.info['wizard_steps'] = ['profiling', 'targeting', 'confirming']
      user.mandate.signature = create(:signature)
      user.mandate.confirmed_at = DateTime.current
      user.mandate.tos_accepted_at = DateTime.current
      user.mandate.state = :in_creation
      user.mandate.complete!
      user
    end

    let!(:questionnaire_one) { create(:questionnaire) }
    let!(:questionnaire_two) { create(:questionnaire) }
    let!(:questionnaire_three) { create(:typeform_questionnaire) }
    let!(:questionnaire_four) { create(:questionnaire) }

    # Add some categories (with questionnaires)
    let!(:category_one) { create(:category, name: 'Private Health Insurance', questionnaire: questionnaire_one) }
    let!(:category_two) { create(:category, name: 'Private Monkey Insurance', questionnaire: questionnaire_two) }
    let!(:category_three) { create(:category, name: 'Söme cätegory MixedCase', questionnaire: questionnaire_three) }
    let!(:category_four) { create(:category, name: 'GDF category', questionnaire: questionnaire_four) }

    # Add a category without a questionnaire
    let!(:category_five) { create(:category, name: 'No questionnaire') }

    before do
      login_as(user, scope: :user)
      request_offer_page.visit_page
    end

    # This also checks that we only show the ones with categories
    it 'should show a list of categories' do
      request_offer_page.expect_visible_category_count(4)
    end

    it 'should show the back button' do
      back_button = '.btn--mobile-block.btn--arrow.btn--arrow--left'
      page.assert_selector(back_button, visible: true)
      expect(find(back_button).text).to eq("#{I18n.t('category_selection.back_cta')}")
    end

    it 'should go back to cockpit when clicking back' do
      request_offer_page.navigate_click('.btn--mobile-block.btn--arrow.btn--arrow--left', 'manager')
    end

    it 'should split up the categories by letter (also checks aplhabetical)' do
      category_item = '.select_category__categories li'

      expect(find("#{category_item}:nth-child(1)").text).to eq('G')
      expect(find("#{category_item}:nth-child(2)").text).to eq('GDF category')
      expect(find("#{category_item}:nth-child(3)").text).to eq('P')
      expect(find("#{category_item}:nth-child(4)").text).to eq('Private Health Insurance')
      expect(find("#{category_item}:nth-child(5)").text).to eq('Private Monkey Insurance')
      expect(find("#{category_item}:nth-child(6)").text).to eq('S')
      expect(find("#{category_item}:nth-child(7)").text).to eq('Söme cätegory MixedCase')
    end

    it 'should have a do questionnaire CTA' do
      page.assert_selector('.btn.btn-primary.btn--arrow.btn--arrow--right', visible: true)
    end

    it 'should have disabled the CTA when no category selected' do
      page.assert_selector('.btn.btn-primary.btn--arrow.btn--arrow--right:disabled', count: 1)
    end

    it 'should select the category when clicking it' do
      category = '.select_category__categories li:nth-child(2)'
      find(category).click()
      page.assert_selector("#{category}.select_category__categories__category--item--active", visible: true, count: 1)
    end

    it 'should only allow one category to be enabled at once' do
      category_one_selector = '.select_category__categories li:nth-child(2)'
      category_two_selector = '.select_category__categories li:nth-child(4)'
      find(category_one_selector).click()
      page.assert_selector("#{category_one_selector}.select_category__categories__category--item--active")
      page.assert_selector('.select_category__categories__category--item--active', count: 1)
      find(category_two_selector).click()
      page.assert_selector("#{category_two_selector}.select_category__categories__category--item--active")
      page.assert_selector('.select_category__categories__category--item--active', count: 1)
    end

    context 'with a category selected' do
      # Create a custom questionnaire
      let!(:ember_questionnaire) { create(:ember_questionnaire) }
      let!(:category_five) { create(:category, name: 'Ember', questionnaire: ember_questionnaire) }


      it 'should enable the main CTA' do
        page.assert_selector('.btn.btn-primary.btn--arrow.btn--arrow--right:disabled')
      end

      it 'should go to the typeform on clicking the main CTA if questionnaire is not supported for custom questionnaire' do
        request_offer_page.select_catagory_with_typeForm_questionnaire_and_click_next
        request_offer_page.expect_to_navigate_to_typeform_questionnaire
      end

      it 'should go to the clark custom questionnaire on clicking the main CTA if custom questionnaire supported' do
        request_offer_page.select_catagory_with_custom_questionnaire_and_click_next
      end

    end

    context 'filtering functionality' do

      # The names of the categories, just a little help comment
      # Private Health Insurance
      # Private Monkey Insurance
      # Söme cätegory MixedCase
      # GDF category

      before do

      end

      it 'should filter with first letter' do
        fill_in('search_input', with: 'p')
        request_offer_page.expect_visible_category_count(2)
        request_offer_page.expect_category_visible(category_one.id)
        request_offer_page.expect_category_visible(category_two.id)
        fill_in('search_input', with: 'g')
        request_offer_page.expect_visible_category_count(1)
        request_offer_page.expect_category_visible(category_four.id)
      end

      it 'should filter with first letter of each word' do
        fill_in('search_input', with: 'pmi')
        request_offer_page.expect_visible_category_count(1)
        request_offer_page.expect_category_visible(category_two.id)
        fill_in('search_input', with: 'scm')
        request_offer_page.expect_visible_category_count(1)
        request_offer_page.expect_category_visible(category_three.id)
        fill_in('search_input', with: 'pi')
        request_offer_page.expect_visible_category_count(2)
        request_offer_page.expect_category_visible(category_one.id)
        request_offer_page.expect_category_visible(category_two.id)
      end

      it 'should match upper and lower case' do
        fill_in('search_input', with: 'private')
        request_offer_page.expect_visible_category_count(2)
        request_offer_page.expect_category_visible(category_one.id)
        request_offer_page.expect_category_visible(category_two.id)
        fill_in('search_input', with: 'Private')
        request_offer_page.expect_visible_category_count(2)
        request_offer_page.expect_category_visible(category_one.id)
        request_offer_page.expect_category_visible(category_two.id)
      end

      it 'should swap out special chars' do
        fill_in('search_input', with: 'some category mixedcase')
        # Two as GDF also has the word category
        request_offer_page.expect_visible_category_count(2)
        request_offer_page.expect_category_visible(category_three.id)
      end

      it 'should show the selected one when filtering even if not matched' do
        category_one_selector = '.select_category__categories li:nth-child(2)'
        find(category_one_selector).click()
        fill_in('search_input', with: 'some category mixedcase')
        request_offer_page.expect_visible_category_count(2)
        # First one is GDF as this is alphabetical
        request_offer_page.expect_category_visible(category_four.id)
        request_offer_page.expect_category_visible(category_three.id)
      end

      it 'should filter on acronyms' do
        fill_in('search_input', with: 'GDF')
        request_offer_page.expect_visible_category_count(1)
        request_offer_page.expect_category_visible(category_four.id)
      end

      it 'should only show letters for the categories visible' do
        fill_in('search_input', with: 'GDF rules')
        request_offer_page.expect_visible_category_count(1)
        request_offer_page.expect_divider('G')
        fill_in('search_input', with: 'category')
        request_offer_page.expect_visible_category_count(2)
        request_offer_page.expect_divider('G')
        request_offer_page.expect_divider('S')
      end

      it 'should clear the input when clicking the clear search X' do
        fill_in('search_input', with: 'Insurance')
        request_offer_page.expect_visible_category_count(2)
        within('.wizard-select-insurance__search-section__inner') do
          find('.clear_input').click()
        end
        request_offer_page.expect_visible_category_count(4)
      end
    end

  end

  # @TODO redirects out are still not working but need to be hooked up at some point
  # context 'no user account' do
  #
  #   it 'should redirect the user out to login page' do
  #     request_offer_page.navigate_to('select-category')
  #     expect(current_path).to eq("/#{I18n.locale}/login")
  #   end
  #
  # end

end
