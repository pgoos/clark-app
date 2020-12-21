require './spec/support/features/page_objects/page_object'
require './spec/support/features/page_objects/ember/ember_helper'

class InvitationPage < PageObject
  attr_reader :path

  def initialize(locale = I18n.locale)
    @locale = locale
    @path = polymorphic_path([:new, :account, :invitation], locale: @locale)
    @emberHelper = EmberHelper.new
    @path_to_register = "/#{locale}/app/mandate/register"
  end

  def navigate
    visit path
  end

  def try_submit(with)
    fill_in('email', with: with)
    find('#sendInvitationEmail').click
  end

  def wait_for_page
    @emberHelper.set_up_ember_transition_hook
    @emberHelper.wait_for_ember_transition
  end

  def expect_register_page
    page.assert_current_path(@path_to_register)
  end
end
