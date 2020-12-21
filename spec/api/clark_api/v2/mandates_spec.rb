# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Mandates, :integration do
  let(:mandate) { create :mandate }
  let(:user)    { create :user, mandate: mandate }
  let(:lead)    { create :lead, mandate: mandate }

  before do
    @configured_locale = I18n.locale
    I18n.locale = :de

    @site = Comfy::Cms::Site.create(
      label: "de", identifier: "de", hostname: TestHost.host_and_port,
      path: "de", locale: "de"
    )
  end

  after do
    I18n.locale = @configured_locale
    @site.destroy
  end

  context "PUT /api/mandates/:id" do
    before do
      @put_params = {
        gender:       "male",
        first_name:   "Karl-Heinz",
        last_name:    "Test",
        street:       "Teststreet",
        house_number: "12",
        zipcode:      "54321",
        city:         "Testhausen",
        birthdate:    30.years.ago.strftime("%d.%m.%Y"),
        iban:         "DE12 5001 0517 0648 4898 90",
        phone:        "+49#{ClarkFaker::PhoneNumber.phone_number}",
        active_at:    "2020-03-30",
        apartment_size: 10
      }
    end

    it "updates the current users mandate" do
      login_as(user, scope: :user)
      json_put_v2 "/api/mandates/#{user.mandate.id}", @put_params

      expect(response.status).to eq(200)
      expect(json_response.mandate.id).to eq(user.mandate.id)
      expect(json_response.mandate.first_name).to eq("Karl-Heinz")
      expect(json_response.mandate.last_name).to eq("Test")
      expect(json_response.mandate.secure_iban).to eq("DE12 **** **** **** **** 90")
      expect(json_response.mandate.phone).to eq(@put_params[:phone])
    end

    it "updates current user manadate address" do
      login_as(lead, scope: :lead)

      json_put_v2 "/api/mandates/#{lead.mandate.id}", @put_params

      expect(response.status).to eq(200)
      expect(json_response.mandate.street).to eq("Teststreet")
      expect(json_response.mandate.house_number).to eq("12")
      expect(json_response.mandate.zipcode).to eq("54321")
      expect(json_response.mandate.city).to eq("Testhausen")
      expect(json_response.mandate.active_at).to eq("2020-03-30")
      expect(json_response.mandate.apartment_size).to eq(10)
    end

    it "updates the current leads mandate" do
      login_as(lead, scope: :lead)

      json_put_v2 "/api/mandates/#{lead.mandate.id}", @put_params

      expect(response.status).to eq(200)
      expect(json_response.mandate.id).to eq(lead.mandate.id)
      expect(json_response.mandate.first_name).to eq("Karl-Heinz")
      expect(json_response.mandate.last_name).to eq("Test")
    end

    it "errors when params are missing" do
      login_as(user, scope: :user)

      json_put_v2 "/api/mandates/#{user.mandate.id}"

      expect(response.status).to eq(400)
    end

    context "when addition_to_address validation" do
      before do
        allow(Settings).to(
          receive_message_chain("addition_to_address.expose")
            .and_return(setting_enabled)
        )
        allow(Settings).to(
          receive_message_chain("addition_to_address.validates_presence")
            .and_return(setting_enabled)
        )

        login_as(user, scope: :user)
        json_put_v2 "/api/mandates/#{user.mandate.id}", params
      end

      describe "is enabled" do
        let(:setting_enabled) { true }

        context "when addition_to_address isn't provided" do
          let(:params) do
            @put_params
          end

          it "returns addition_to_address error" do
            expect(response.status).to eq(400)
            expect(json_response.dig(:errors, :mandate, :addition_to_address)).to(
              be_present
            )
          end
        end

        context "when addition_to_address is provided" do
          let(:params) do
            @put_params.merge(addition_to_address: "Nadya Court")
          end

          it "Updates the mandate" do
            expect(response.status).to eq(200)
            expect(json_response.mandate.id).to eq(lead.mandate.id)
            expect(json_response.mandate.addition_to_address).to eq("Nadya Court")
          end
        end
      end

      describe "is disabled" do
        let(:setting_enabled) { false }

        let(:params) do
          @put_params.merge(addition_to_address: "Nadya Court")
        end

        it "Filters out addition_to_address" do
          expect(response.status).to eq(200)
          expect(json_response.mandate.id).to eq(lead.mandate.id)
          expect(json_response.mandate).not_to(
            be_key("addition_to_address")
          )
        end
      end
    end

    it "errors when the mandate id does not match" do
      login_as(user, scope: :user)

      json_put_v2 "/api/mandates/0", @put_params

      expect(response.status).to eq(404)
      expect(Mandate.find(user.mandate.id).first_name).not_to eq("Karl-Heinz")
      expect(Mandate.find(user.mandate.id).last_name).not_to eq("Test")
    end

    it "returns 401 if the user is not singed in" do
      json_put_v2 "/api/mandates/#{user.mandate.id}", @put_params
      expect(response.status).to eq(401)
    end

    context "transfer_data_to_bank flag" do
      before do
        @put_params[:transfer_data_to_bank] = true
      end

      it "expose the transfer_data_to_bank flag and changes the value" do
        login_as(user, scope: :user)
        json_put_v2 "/api/mandates/#{user.mandate.id}", @put_params

        expect(response.status).to eq(200)
        expect(user.mandate.transfer_data_to_bank).to be_truthy
        expect(json_response.mandate.info["transfer_data_to_bank"]).to be_truthy
      end
    end

    context "when iban is already persisted" do
      let(:mandate) { create :mandate, iban: "DE12 5001 0517 0648 4898 90" }
      let(:user)    { create :user, mandate: mandate }

      before do
        @put_params[:iban] = nil
      end

      it "does not change it when nil" do
        login_as(user, scope: :user)
        json_put_v2 "/api/mandates/#{user.mandate.id}", @put_params

        expect(json_response.mandate.secure_iban).to eq("DE12 **** **** **** **** 90")
        expect(user.mandate.iban?).to be true
      end
    end
  end

  context "PATCH /api/mandates/:id" do
    iban = "DE12 5001 0517 0648 4898 90"
    before do
      @put_params = {
        mandate: {
          iban: iban
        }
      }
    end

    it "updates the current users mandate" do
      login_as(user, scope: :user)

      json_patch_v2 "/api/mandates/#{user.mandate.id}", @put_params

      user.mandate.reload

      expect(response.status).to eq(200)
      expect(json_response.mandate.id).to eq(user.mandate.id)
      expect(user.mandate.iban_for_display(true)).to eq(iban)
    end

    it "updates the current leads mandate" do
      login_as(lead, scope: :lead)

      json_patch_v2 "/api/mandates/#{lead.mandate.id}", @put_params

      lead.mandate.reload

      expect(response.status).to eq(200)
      expect(json_response.mandate.id).to eq(lead.mandate.id)
      expect(lead.mandate.iban_for_display(true)).to eq(iban)
    end

    it "errors with non valid iban" do
      login_as(lead, scope: :lead)

      non_valid_params = {
        mandate: {
          iban: "DE1200105170648489890"
        }
      }

      json_patch_v2 "/api/mandates/#{lead.mandate.id}", non_valid_params

      lead.mandate.reload

      expect(response.status).to eq(400)
      expect(lead.mandate.iban_for_display(true)).to eq(nil)
    end

    it "errors with iban raising a runtime error" do
      login_as(lead, scope: :lead)

      non_valid_params = {
        mandate: {
          iban: ":DE12 5001 0517 0648 4898 90" # the iban gem can't handle characters like ':'
        }
      }

      json_patch_v2 "/api/mandates/#{lead.mandate.id}", non_valid_params

      lead.mandate.reload

      expect(response.status).to eq(400)
      expect(lead.mandate.iban_for_display(true)).to eq(nil)
    end

    it "errors when the mandate id does not match" do
      login_as(user, scope: :user)

      json_patch_v2 "/api/mandates/0", @put_params

      expect(response.status).to eq(404)
    end

    it "returns 401 if the user is not singed in" do
      json_patch_v2 "/api/mandates/#{user.mandate.id}", @put_params
      expect(response.status).to eq(401)
    end
  end

  context "POST /api/mandates/:id/signatures" do
    before do
      @signature = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAADElEQVQImWNgoBMAAABpAAFEI8ARAAAAAElFTkSuQmCC"
    end

    it "creates a new signature and adds it to the mandate as a user" do
      login_as(user, scope: :user)

      json_post_v2 "/api/mandates/#{user.mandate.id}/signatures", signature: @signature

      expect("data:image/png;base64,#{Base64.strict_encode64(Mandate.find(user.mandate.id).signature.asset.read)}").to eq(@signature)
      expect(response.status).to eq(201)
    end

    it "creates a new signature and adds it to the mandate as a lead" do
      login_as(lead, scope: :lead)

      json_post_v2 "/api/mandates/#{lead.mandate.id}/signatures", signature: @signature

      expect("data:image/png;base64,#{Base64.strict_encode64(Mandate.find(lead.mandate.id).signature.asset.read)}").to eq(@signature)
      expect(response.status).to eq(201)
    end

    it "overrides a existing signature as a user" do
      create(:signature, signable: user.mandate)

      login_as(user, scope: :user)

      json_post_v2 "/api/mandates/#{user.mandate.id}/signatures", signature: @signature

      expect("data:image/png;base64,#{Base64.strict_encode64(Mandate.find(user.mandate.id).signature.asset.read)}").to eq(@signature)
      expect(response.status).to eq(201)
    end

    it "returns 401 if the user is not singed in" do
      json_post_v2 "/api/mandates/#{user.mandate.id}/signatures", signature: @signature

      expect(response.status).to eq(401)
    end
  end

  context "GET /api/mandates/:id/inquiries" do
    it "gets all the inquiries associated with the mandate as a user" do
      login_as(user, scope: :user)

      create(:inquiry, mandate_id: user.mandate.id)

      json_get_v2 "/api/mandates/#{user.mandate.id}/inquiries"

      expect(response.status).to eq(200)
      expect(json_response.inquiries.count).to be 1
    end

    it "gets all the inquiries associated with the mandate as a lead" do
      login_as(lead, scope: :lead)

      create(:inquiry, mandate_id: lead.mandate.id)

      json_get_v2 "/api/mandates/#{lead.mandate.id}/inquiries"

      expect(response.status).to eq(200)
      expect(json_response.inquiries.count).to be 1
    end

    it "returns 401 if the user is not singed in" do
      json_get_v2 "/api/mandates/#{user.mandate.id}/inquiries"
      expect(response.status).to eq(401)
    end
  end

  context "POST /api/mandates/:id/inquiries" do
    before do
      @company = create(:company)
    end

    it "creates a new inquiry associated with the mandate as a user" do
      login_as(user, scope: :user)

      expect {
        json_post_v2 "/api/mandates/#{user.mandate.id}/inquiries", company_id: @company.id
      }.to change { user.mandate.inquiries.count }.by(1)

      expect(response.status).to eq(201)
    end

    it "has the correct company id added to the inquiry" do
      login_as(user, scope: :user)

      expect {
        json_post_v2 "/api/mandates/#{user.mandate.id}/inquiries", company_id: @company.id
      }.to change { user.mandate.inquiries.count }.by(1)

      expect(user.mandate.inquiries.last.company_id).to eq(@company.id)
    end

    it "creates a new inquiry associated with the mandate as a lead" do
      login_as(lead, scope: :lead)

      expect {
        json_post_v2 "/api/mandates/#{lead.mandate.id}/inquiries", company_id: @company.id
      }.to change { lead.mandate.inquiries.count }.by(1)

      expect(response.status).to eq(201)
    end

    it "returns 401 if the user is not singed in" do
      expect {
        json_post_v2 "/api/mandates/#{user.mandate.id}/inquiries", company_id: @company.id
      }.to change { user.mandate.inquiries.count }.by(0)

      expect(response.status).to eq(401)
    end
  end

  describe "PATCH /api/mandates/:id/accept_health_consent" do
    let(:mandate) { create :mandate, health_consent_accepted_at: nil }

    it "returns 401 if the user is not singed in" do
      json_patch_v2 "/api/mandates/#{user.mandate.id}/health_consent"
      expect(response.status).to eq(401)
    end

    it "sets acceptance date for health consent" do
      login_as(user, scope: :user)
      json_patch_v2 "/api/mandates/#{user.mandate.id}/health_consent"

      expect(user.mandate.reload.health_consent_accepted_at).not_to be_blank
      expect(response.status).to eq 200
    end
  end

  describe "PUT /api/mandates/:id/non_binding_appointment" do
    let(:put_params) {
      {
        id: 0,
        gender: "male",
        first_name: "Karl-Heinz",
        last_name: "Test",
        company: "some company",
        job_title: "some job title",
        phone: "+49#{ClarkFaker::PhoneNumber.phone_number}",
        email: "gareth-rocks@gmail.com"
      }
    }

    let(:mailer_params) do
      admin_mandate_url = admin_mandate_url(:de, mandate, host: TestHost.host_and_port)
      {
        mandate: admin_mandate_url,
        gender: "male",
        first_name: "Karl-Heinz",
        last_name: "Test",
        company: "some company",
        job_title: "some job title",
        phone: put_params[:phone],
        email: "gareth-rocks@gmail.com",
        topic: "unverbindlichen Termin"
      }
    end

    let(:mailer) { double(ApplicationMailer) }

    before do
      allow(ApplicationMailer).to receive(:non_binding_callback).with(mailer_params) { mailer }
      allow(mailer).to receive(:deliver_now)
    end

    it "returns 404 if cannot find the user" do
      json_put_v2 "/api/mandates/#{mandate.id}/non_binding_appointment", put_params
      expect(response.status).to eq(404)
    end

    it "errors when params are missing" do
      login_as(user, scope: :user)
      json_put_v2 "/api/mandates/#{mandate.id}/non_binding_appointment", {}

      expect(response.status).to eq(400)
    end

    it "works as expected with a user" do
      login_as(user, scope: :user)

      put_params[:id] = mandate.id

      # Make the put with the sample payload
      json_put_v2 "/api/mandates/#{mandate.id}/non_binding_appointment", put_params

      # Make sure she updated the mandate correctly
      expect(json_response.mandate.id).to eq(mandate.id)
      expect(json_response.mandate.first_name).to eq(put_params[:first_name])
      expect(json_response.mandate.last_name).to eq(put_params[:last_name])
      expect(json_response.mandate.gender).to eq(put_params[:gender])
      expect(json_response.mandate.phone).to eq(put_params[:phone])

      # Make sure the users email and fb data is correct
      user.reload

      expect(user.email).to eq("gareth-rocks@gmail.com")
      expect(user.customer_related["company"]).to eq(put_params[:company])
      expect(user.customer_related["job_title"]).to eq(put_params[:job_title])
      # And has the terms
      expect(user.customer_related["non_binding_appointment_terms_accepted_at"]).not_to be_empty

      # sent the email
      expect(mailer).to have_received(:deliver_now)

      expect(response.status).to eq 200
    end

    it "works as expected with a lead" do
      login_as(lead, scope: :lead)

      put_params[:id] = mandate.id

      # Make the put with the sample payload
      json_put_v2 "/api/mandates/#{mandate.id}/non_binding_appointment", put_params

      # Make sure she updated the mandate correctly
      expect(json_response.mandate.id).to eq(mandate.id)
      expect(json_response.mandate.first_name).to eq(put_params[:first_name])
      expect(json_response.mandate.last_name).to eq(put_params[:last_name])
      expect(json_response.mandate.gender).to eq(put_params[:gender])
      expect(json_response.mandate.phone).to eq(put_params[:phone])

      # Make sure the leads email and fb data is correct
      lead.reload

      expect(lead.email).to eq("gareth-rocks@gmail.com")
      expect(lead.customer_related["company"]).to eq(put_params[:company])
      expect(lead.customer_related["job_title"]).to eq(put_params[:job_title])
      # And has the terms
      expect(lead.customer_related["non_binding_appointment_terms_accepted_at"]).not_to be_empty

      expect(response.status).to eq 200
    end
  end
end
