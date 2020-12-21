require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'


class ManagerNumberOneRecModal < PageObject
  include FeatureHelpers


  def initialize(locale = I18n.locale)
    @locale      = locale
    @emberHelper = EmberHelper.new
  end

  def modal_shows_up
    page.assert_selector('.ember-modal', visible: true)
  end

  def modal_has_description(text)
    expect(find(".manager__optimisations__numberone__rec__bottom_section__top__text").text).to eq(text)
  end

  def category_has_name(text)
    expect(find(".manager__optimisations__numberone__rec__bottom_section__bottom__category").text).to eq(text)
  end

  def expect_agent_picture
    page.assert_selector(".manager__optimisations__numberone__rec__top-section__agent-pic")
  end

  def expect_brand_logo
    page.assert_selector(".manager__optimisations__numberone__rec__top-section__left__brand-logo")
  end

  def expect_your_insurer_text
    page.assert_selector(".manager__optimisations__numberone__rec__top-section__right__desingnation--insurer")
  end

  def expect_agent(agent_name)
    expect(find(".manager__optimisations__numberone__rec__top-section__right__name").text).to eq(agent_name)
  end

  def expect_agent_role(role)
    expect(find(".manager__optimisations__numberone__rec__top-section__right__desingnation").text).to eq(role)
  end

  def expect_no_agent_details
    expect(page).not_to have_selector(".manager__optimisations__numberone__rec__top-section__right__name")
    expect(page).not_to have_selector(".manager__optimisations__numberone__rec__top-section__right__desingnation")
  end

  def has_cta(text)
    find_button(text)
  end
end
