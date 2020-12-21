module ControllerHelpers
  def login_admin(admin=nil)
    @request.env["devise.mapping"] = Devise.mappings[:admin]
    admin ||= create(:admin,
                                 email: "superadmin@example.com",
                                 role: Role.find_by(identifier: 'super_admin'))
    sign_in admin
  end

  def json_response
    Hashie::Mash.new(JSON.parse(response.body))
  end
end
