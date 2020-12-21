# frozen_string_literal: true

module AdminSpecHelpers
  def find_or_create_first_admin(attributes={})
    Admin.first || create(:admin, attributes)
  end

  def generate_password(count=1)
    Settings.seeds.default_password + count.to_s
  end
end
