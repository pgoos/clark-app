require 'rails_helper'
require 'support/api_schema_matcher'
require 'ostruct'

include ApiSchemaMatcher

RSpec.describe ClarkAPI::V2::App::Devices, :integration do

  context 'POST /api/app/devices' do
    it 'creates a new device and returns 201' do
      user = create(:user, mandate: create(:mandate))
      login_as(user, :scope => :user)

      expect {
        json_post_v2 '/api/app/devices', {device: {installation_id: '12321343343c32cc2c2c23324234c', os: 'ios', os_version: '1', manufacturer: 'HTC', model: 'one'}}
      }.to change { Device.all.count }.by(1)

      expect(response.status).to eq(201)
    end


    it 'null tokens can be multiple' do
      user = create(:user, mandate: create(:mandate))
      create(:device, user_id: user.id, token: nil)
      login_as(user, :scope => :user)

      expect {
        json_post_v2 '/api/app/devices', {device: {installation_id: '12321343343c32cc2c2c23324234c', os: 'ios', os_version: '1', manufacturer: 'HTC', model: 'one'}}
      }.to change { Device.count }.by(1)
      expect(response.status).to eq(201)
    end

    it 'updates a existing device and returns 201' do
      user = create(:user, mandate: create(:mandate))
      device = create(:device, user_id: user.id)
      login_as(user, :scope => :user)

      expect {
        json_post_v2 '/api/app/devices', {device: {installation_id: device.installation_id, os: 'ios', os_version: '2', manufacturer: 'HTC', model: 'one'}}
      }.not_to change { Device.all.count }

      expect(response.status).to eq(201)
    end

    it 'switch device to another user' do
      user = create(:user, mandate: create(:mandate))
      device = create(:device, user: create(:user)) # Create device with another user
      login_as(user, :scope => :user)

      expect {
        json_post_v2 '/api/app/devices', {device: {installation_id: device.installation_id, os: 'ios', os_version: '2', manufacturer: 'HTC', model: 'one', permissions: {push_enabled: true, tracking: false}}}
      }.not_to change { Device.all.count }

      expect(response.status).to eq(201)
      device.reload
      expect(device.user_id).to eq(user.id)
    end

    it 'Missing installation_id returns a 400' do
      device_count = Device.all.count
      user = create(:user, mandate: create(:mandate))
      login_as(user, :scope => :user)

      json_post_v2 '/api/app/devices', {device: {os: 'ios', os_version: '1', manufacturer: 'HTC', model: 'one'}}

      expect(response.status).to eq(400)
      expect(Device.all.count).to eq(device_count)
    end

    it 'only accepts ios or android operating systems' do
      user = create(:user, mandate: create(:mandate))
      login_as(user, :scope => :user)

      json_post_v2 '/api/app/devices', {device: {installation_id: '7eb7cfedef752d762a8280a66572b451006a2b6edf4096bef158415fda73e411', os: 'bada', os_version: '1', manufacturer: 'HTC', model: 'one'}}

      expect(response.status).to eq(400)
      expect(response.body).to eq('{"errors":{"device":{"os":["ist kein gültiger Wert"]}}}')
    end

    it 'creates a device when logged in as a lead' do
      device_lead = create(:device_lead, mandate: create(:mandate))
      login_as(device_lead, :scope => :lead)

      expect {
        json_post_v2 '/api/app/devices', {device: {installation_id: device_lead.installation_id, os: 'ios', os_version: '1', manufacturer: 'HTC', model: 'one'}}
      }.to change { Device.all.count }.by(1)

      expect(response.status).to eq(201)
    end

    it 'not logged in user returns a 401' do
      json_post_v2 '/api/app/devices', {device: {installation_id: '7eb7cfedef752d762a8280a66572b451006a2b6edf4096bef158415fda73e411', os: 'ios', os_version: '1', manufacturer: 'HTC', model: 'one'}}

      expect(response.status).to eq(401)
      expect(response.body).to eq('{"error":"not logged in"}')
    end

    it 'stores the advertiser id gps_adid with the device' do
      expected_id = 'XYZ987'

      user = create(:user, mandate: create(:mandate))
      login_as(user, :scope => :user)

      expect {
        json_post_v2 '/api/app/devices', {device: {installation_id: '12321343343c32cc2c2c23324234c', os: 'ios', os_version: '1', manufacturer: 'HTC', model: 'one'}, gps_adid: expected_id}
      }.to change { Device.all.count }.by(1)

      expect(Device.last.advertiser_id).to eq(expected_id)
      expect(Device.last.advertiser_id_type).to eq('gps_adid')
    end

    it 'stores no advertiser id if nothing given' do
      user = create(:user, mandate: create(:mandate))
      login_as(user, :scope => :user)

      expect {
        json_post_v2 '/api/app/devices', {device: {installation_id: '12321343343c32cc2c2c23324234c', os: 'ios', os_version: '1', manufacturer: 'HTC', model: 'one'}}
      }.to change { Device.all.count }.by(1)

      expect(Device.last.advertiser_id).to be_blank
      expect(Device.last.advertiser_id_type).to be_blank
    end

    it 'updates the advertiser id gps_adid of an existing device' do
      expected_id = 'ABC123'
      user = create(:user, mandate: create(:mandate))
      device = create(:device, user_id: user.id, advertiser_id: 'old_id', advertiser_id_type: 'old_type')
      login_as(user, :scope => :user)

      expect {
        json_post_v2 '/api/app/devices', {device: {installation_id: device.installation_id, os: 'ios', os_version: '2', manufacturer: 'HTC', model: 'one'}, gps_adid: expected_id}
      }.not_to change { Device.all.count }

      expect(Device.last.advertiser_id).to eq(expected_id)
      expect(Device.last.advertiser_id_type).to eq('gps_adid')
    end

    it 'stores the advertiser id idfa with the device' do
      expected_id = 'XYZ987'

      user = create(:user, mandate: create(:mandate))
      login_as(user, :scope => :user)

      expect {
        json_post_v2 '/api/app/devices', {device: {installation_id: '12321343343c32cc2c2c23324234c', os: 'ios', os_version: '1', manufacturer: 'HTC', model: 'one'}, idfa: expected_id}
      }.to change { Device.all.count }.by(1)

      expect(Device.last.advertiser_id).to eq(expected_id)
      expect(Device.last.advertiser_id_type).to eq('idfa')
    end

    it 'updates the advertiser id idfa of an existing device' do
      expected_id = 'ABC123'
      user = create(:user, mandate: create(:mandate))
      device = create(:device, user_id: user.id, advertiser_id: 'old_id', advertiser_id_type: 'old_type')
      login_as(user, :scope => :user)

      expect {
        json_post_v2 '/api/app/devices', {device: {installation_id: device.installation_id, os: 'ios', os_version: '2', manufacturer: 'HTC', model: 'one'}, idfa: expected_id}
      }.not_to change { Device.all.count }

      expect(Device.last.advertiser_id).to eq(expected_id)
      expect(Device.last.advertiser_id_type).to eq('idfa')
    end
  end

  context "PATCH /api/app/devices" do
    it "Missing installation_id returns a 400" do
      device_count = Device.all.count
      user = create(:user, mandate: create(:mandate))
      login_as(user, scope: :user)

      json_patch_v2 "/api/app/devices", { device: { push_enabled: false } }

      expect(response.status).to eq(400)
      expect(Device.all.count).to eq(device_count)
    end

    it "not logged in user returns a 401" do
      json_patch_v2 "/api/app/devices", {
        device: {
          installation_id: "7eb7cfedef752d762a8280a66572b451006a2b6edf4096bef158415fda73e411",
          permissions: {
            push_enabled: false
          }
        }
      }

      expect(response.status).to eq(401)
      expect(response.body).to eq('{"error":"not logged in"}')
    end

    it "does not create a new device and returns 201" do
      user = create(:user, mandate: create(:mandate))
      login_as(user, scope: :user)

      expect {
        json_patch_v2 "/api/app/devices", {
          device: {
            installation_id: "12321343343c32cc2c2c23324234c",
            permissions: {
              push_enabled: false
            }
          }
        }
      }.to change { Device.all.count }.by(0)

      expect(response.status).to eq(400)
    end

    it "enables push permission" do
      user = create(:user, mandate: create(:mandate))
      device = create(:device, user: create(:user), permissions: { push_enabled: false })
      login_as(user, scope: :user)

      json_patch_v2 "/api/app/devices", {
        device: {
          installation_id: device.installation_id,
          permissions: {
            push_enabled: true
          }
        }
      }

      device.reload

      expect(response.status).to eq(200)
      expect(device.push_enabled).to eq(true)
      expect(device.token).not_to be_nil
    end

    it "disables push permission" do
      user = create(:user, mandate: create(:mandate))
      device = create(:device, user: create(:user))
      login_as(user, scope: :user)

      json_patch_v2 "/api/app/devices", {
        device: {
          installation_id: device.installation_id,
          permissions: {
            push_enabled: false
          }
        }
      }

      device.reload

      expect(response.status).to eq(200)
      expect(device.push_enabled).to eq(false)
    end

    it "sets the right push token" do
      user = create(:user, mandate: create(:mandate))
      device = create(:device, user: create(:user))
      login_as(user, scope: :user)

      json_patch_v2 "/api/app/devices", {
        device: {
          installation_id: device.installation_id,
          token: "test_token_123"
        }
      }

      device.reload

      expect(response.status).to eq(200)
      expect(device.token).to eq("test_token_123")
    end

    it "sets correct os" do
      user = create(:user, mandate: create(:mandate))
      device = create(:device, user: create(:user))
      login_as(user, scope: :user)

      json_patch_v2 "/api/app/devices", {
        device: {
          installation_id: device.installation_id,
          os: "android"
        }
      }

      device.reload

      expect(response.status).to eq(200)
      expect(device.os).to eq("android")
    end

    it "sets os version" do
      user = create(:user, mandate: create(:mandate))
      device = create(:device, user: create(:user))
      login_as(user, scope: :user)

      json_patch_v2 "/api/app/devices", {
        device: {
          installation_id: device.installation_id,
          os_version: "test_os_version"
        }
      }

      device.reload

      expect(response.status).to eq(200)
      expect(device.os_version).to eq("test_os_version")
    end

    it "sets manufacturer" do
      user = create(:user, mandate: create(:mandate))
      device = create(:device, user: create(:user))
      login_as(user, scope: :user)

      json_patch_v2 "/api/app/devices", {
        device: {
          installation_id: device.installation_id,
          manufacturer: "test_manufacturer"
        }
      }

      device.reload

      expect(response.status).to eq(200)
      expect(device.manufacturer).to eq("test_manufacturer")
    end

    it "sets model" do
      user = create(:user, mandate: create(:mandate))
      device = create(:device, user: create(:user))
      login_as(user, scope: :user)

      json_patch_v2 "/api/app/devices", {
        device: {
          installation_id: device.installation_id,
          model: "test_model"
        }
      }

      device.reload

      expect(response.status).to eq(200)
      expect(device.model).to eq("test_model")
    end

    it "disables tracking" do
      user = create(:user, mandate: create(:mandate))
      device = create(:device, user: create(:user))
      login_as(user, scope: :user)

      json_patch_v2 "/api/app/devices", {
        device: {
          installation_id: device.installation_id,
          permissions: {
            tracking: false
          }
        }
      }

      device.reload

      expect(response.status).to eq(200)
      expect(device.tracking).to eq(false)
    end

    it "enables tracking" do
      user = create(:user, mandate: create(:mandate))
      device = create(:device, user: create(:user))
      login_as(user, scope: :user)

      json_patch_v2 "/api/app/devices", {
        device: {
          installation_id: device.installation_id,
          permissions: {
            tracking: true
          }
        }
      }

      device.reload

      expect(response.status).to eq(200)
      expect(device.tracking).to eq(true)
    end

    it "filters out nil values" do
      user = create(:user, mandate: create(:mandate))
      device = create(:device, user: create(:user))
      login_as(user, scope: :user)

      json_patch_v2 "/api/app/devices", {
        device: {
          installation_id: device.installation_id,
          model: "test_model"
        }
      }

      device.reload

      expect(response.status).to eq(200)
      expect(device.model).to eq("test_model")
      expect(device.os_version).not_to eq("test_os_version")

      json_patch_v2 "/api/app/devices", {
        device: {
          installation_id: device.installation_id,
          os_version: "test_os_version"
        }
      }

      device.reload

      expect(device.model).to eq("test_model")
      expect(device.os_version).to eq("test_os_version")
    end
  end
end
