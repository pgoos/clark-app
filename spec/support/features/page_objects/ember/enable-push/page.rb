require './spec/support/features/page_objects/page_object'

class EnablePushPage < PageObject
  include FeatureHelpers

  def initialize(locale = I18n.locale)
    @locale = locale
    @path_to_manager = "/#{locale}/app/manager"
    @path_to_push = "/#{locale}/app/enable-push"
  end

  # Navigation helpers to go to views at the start of tests
  def navigate_manager
    visit @path_to_manager
    mock_and_clean
  end

  def mock_and_clean
    clean_up
  end

  # Checking if navigated / not navigated to the push notification view
  def assert_navigated_to_enable_push
    page.assert_current_path(@path_to_push)
  end

  def assert_not_navigated_to_enable_push
    sleep 2
    expect(current_path).not_to eq(@path_to_push)
  end

  # Testing the existance of page elements in the push modal
  def assert_correct_username(mandate)
    within('push-notification-splash__intro') do
      assert_text("#{I18n.t('push_notification_splash.intro', user_name: mandate.first_name)}")
    end
  end

  def assert_icon_visible
    page.assert_selector('.push-notification-splash__icon')
  end

  def assert_has_cta
    expect(find('.push-notification-splash__ctas__cta .btn').text).to eq("#{I18n.t('push_notification_splash.cta')}")
  end

  def assert_correct_copy
    expect(find('.push-notification-splash__content').text).to eq("#{I18n.t('push_notification_splash.content')}")
  end

  # Set a user journey event on the clark user journey store
  def set_event(event)
    Capybara.current_session.execute_script "window.localStorage.setItem('clark-user-journey', JSON.stringify({states: '#{event}'}))"
  end

  # Set local storage value for push enabled
  def set_push_enabled(value)
    Capybara.current_session.execute_script "window.localStorage.setItem('clark-user-journey', '#{value}')"
  end

  # Clears the journey and clark rate us events like push enabled flag
  def clean_up
    Capybara.current_session.execute_script "window.localStorage.removeItem('pushEnabled');window.localStorage.removeItem('clark-user-journey');"
  end

  # Set the default version as one behined so we trigger rating, as only rated old version
  def set_rating(rating: '5', states: '[]', version: '170')
    Capybara.current_session.execute_script "window.localStorage.setItem('clark-rating', JSON.stringify({rating:#{rating}, states:#{states}, version:#{version}}))"
  end

end
