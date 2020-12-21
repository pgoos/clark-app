# frozen_string_literal: true

require "rails_helper"

describe ClarkAPI::Partners::Mandates, :integration do
  let(:png_file) { fixture_file_upload(Rails.root.join("spec", "fixtures", "empty_signature.png")) }
  let(:pdf_file) { fixture_file_upload(Rails.root.join("spec", "fixtures", "dummy-mandate.pdf")) }

  let(:endpoint) { "/api/mandates" }
  let(:client) { create(:api_partner) }
  let(:access_token) { client.access_token_for_instance("test")["value"] }

  before do
    client.save_secret_key!("raw")
    client.update_access_token_for_instance!("test")

    allow(Features).to receive(:active?).and_return(false)
  end

  describe "POST /api/mandates" do
    let(:user) { create(:user) }

    it_behaves_like "unathorized endpoint of the partnership api"

    context "only basic params are presented" do
      let(:mandate) { build(:mandate, user: user, first_name: "O'Donnell") }
      let(:basic_mandate_attrs) do
        mandate.attributes.select { |attribute|
          %w[first_name last_name birthdate email].include?(attribute)
        }
      end

      context "mandate doesn't exists" do
        before do
          partners_post endpoint,
                        payload_hash: {mandate: basic_mandate_attrs},
                        headers:      {"Authorization" => access_token}
        end

        it "returns 400" do
          expect(response.status).to eq(400)
        end

        it "returns the mandate object" do
          expect(response.body).to match_response_schema("partners/20170213/error")
        end
      end

      context "mandate does exists, but signup wasn't completed" do
        let(:mandate) { create(:mandate, user: user, first_name: "O'Donnell") }

        before do
          partners_post endpoint,
                        payload_hash: {mandate: basic_mandate_attrs},
                        headers:      {"Authorization" => access_token}
        end

        it "returns 400" do
          expect(response.status).to eq(400)
        end

        it "returns the mandate object" do
          expect(response.body).to match_response_schema("partners/20170213/error")
        end
      end

      context "mandate does exists and signup is completed" do
        let(:mandate) { create(:mandate, user: user, first_name: "O'Donnell") }

        before do
          mandate.complete!
          partners_post endpoint,
                        payload_hash: {mandate: basic_mandate_attrs.merge(email: user.email)},
                        headers:      {"Authorization" => access_token}
        end

        it "returns 200" do
          expect(response.status).to eq(200)
        end

        it "returns the mandate object" do
          expect(response.body).to match_response_schema("partners/20170213/mandate")
        end
      end
    end

    context "all request params are presented" do
      context "but have some validation error" do
        let(:mandate_attributes) do
          build(:mandate).attributes.merge(email: Faker::Internet.email)
        end

        it "returns an error when request param is missing" do
          partners_post endpoint, headers: {"Authorization" => access_token}
          expect(response.status).to eq(400)
          expect(response.body).to match_response_schema("partners/20170213/error")
        end

        it "returns an error when a country code is not ISO3166 value" do
          mandate_attributes[:country_code] = "DEU"

          partners_post endpoint,
                        payload_hash: {mandate: mandate_attributes},
                        headers:      {"Authorization" => access_token}
          expect(response.status).to eq(400)
          expect(response.body).to match_response_schema("partners/20170213/error")
        end

        it "returns an error when a gender value is not valid" do
          mandate_attributes[:gender] = "MALE"

          partners_post endpoint,
                        payload_hash: {mandate: mandate_attributes},
                        headers:      {"Authorization" => access_token}
          expect(response.status).to eq(400)
          expect(response.body).to match_response_schema("partners/20170213/error")
        end
      end

      context "and are valid, mandate doesn't exists" do
        before do
          email         = Faker::Internet.email
          address_attrs = attributes_for :address
          mandate_attrs = attributes_for(:mandate, email: email).merge(address_attrs)

          partners_post endpoint,
                        payload_hash: {mandate: mandate_attrs},
                        headers:      {"Authorization" => access_token}
        end

        it "has correct source" do
          mandate = Mandate.find(JSON.parse(response.body)["mandate"]["id"])
          expect(mandate.user_or_lead.source_data["adjust"]["network"])
            .to eq(client.partnership_ident)
        end

        it "returns 201" do
          expect(response.status).to eq(201)
        end

        it "returns the mandate object" do
          expect(response.body).to match_response_schema("partners/20170213/mandate")
        end
      end

      context "params are valid, but feature switch 'DISABLE_DISALLOWED_API_PARTNER_MANDATE_CREATION' is on" do
        before do
          allow(Features)
            .to receive(:active?)
            .with(Features::DISABLE_DISALLOWED_API_PARTNER_MANDATE_CREATION)
            .and_return(true)
        end

        context "this partner is not in the set of partners disallowed from creating mandates" do
          before do
            email         = Faker::Internet.email
            address_attrs = attributes_for :address
            mandate_attrs = attributes_for(:mandate, email: email).merge(address_attrs)

            partners_post endpoint,
                          payload_hash: { mandate: mandate_attrs },
                          headers:      { "Authorization" => access_token }
          end

          it "returns 201" do
            expect(response.status).to eq(201)
          end
        end

        context "this partner is in the set of partners disallowed from creating mandates" do
          ClarkAPI::Partners::Helpers::Authentication::MANDATE_CREATION_DISALLOWED_PARTNERS.each do |partnership_ident|
            let(:client) { create(:api_partner, partnership_ident: partnership_ident) }
            let(:access_token) { client.access_token_for_instance("test")["value"] }
            before do
              client.save_secret_key!("raw")
              client.update_access_token_for_instance!("test")

              address_attrs = attributes_for :address
              mandate_attrs = attributes_for(:mandate, email: Faker::Internet.email).merge(address_attrs)

              partners_post endpoint,
                            payload_hash: { mandate: mandate_attrs },
                            headers:      { "Authorization" => access_token }
            end

            it "returns 403 forbidden error" do
              expect(response.status).to eq(403)
            end
          end
        end
      end

      context "mandate does exists and was acquired by a partner" do
        before do
          email         = Faker::Internet.email
          address_attrs = attributes_for(:address)
          mandate_attrs = attributes_for(
            :mandate,
            first_name: "O'Donnell",
            email: email
          ).merge(address_attrs)

          2.times do
            partners_post endpoint, payload_hash: {mandate: mandate_attrs},
                                    headers:      {"Authorization" => access_token}
          end
        end

        it "returns 409 http status" do
          expect(response.status).to eq(409)
        end

        it "returns an error object with mandate id" do
          expect(response.body)
            .to match_response_schema("partners/20170213/error_conflict_mandate")
        end
      end

      context "mandate does exists with completed signup and was acquired by Clark" do
        let(:email) { Faker::Internet.email }
        let(:user) { create(:user, email: email) }
        let(:mandate) do
          create(:mandate, first_name: "Rory",
                           last_name: "",
                           user: user,
                           gender: nil)
        end
        let(:mandate_attributes) do
          mandate.attributes.merge(
            email: email, last_name: "O'Donnell", gender: :male
          )
        end

        before do
          mandate.complete!
          partners_post endpoint, payload_hash: {mandate: mandate_attributes},
                                  headers:      {"Authorization" => access_token}
          mandate.reload
        end

        it "updates missing data fields with partner payload" do
          expect(mandate.last_name).not_to eq(nil)
          expect(mandate.gender).to eq("male")
        end

        it "returns 409 http status" do
          expect(response.status).to eq(409)
        end

        it "returns an error object with mandate id" do
          expect(response.body)
            .to match_response_schema("partners/20170213/error_conflict_mandate")
        end
      end

      context "mandate was acquired by Clark, and it has different name on the partner side" do
        before do
          email              = Faker::Internet.email
          user               = create(:user, email: email)
          mandate            = create(:mandate, user: user)
          mandate_attributes = mandate.attributes.merge(
            email:      email,
            first_name: "#{mandate.first_name} Axel"
          )
          mandate.complete!
          mandate.accept!

          partners_post endpoint, payload_hash: {mandate: mandate_attributes},
                                   headers:      {"Authorization" => access_token}
        end

        it "returns 409 http status" do
          expect(response.status).to eq(409)
        end

        it "returns an error object with mandate id" do
          expect(response.body)
            .to match_response_schema("partners/20170213/error_conflict_mandate")
        end
      end

      context "acquired by Clark mandate does exists with a lead and not completed signup" do
        before do
          email   = Faker::Internet.email
          lead    = create(:lead, email: email)
          existing_mandate = create(:mandate, lead: lead, first_name: nil, last_name: nil)

          mandate_attributes = existing_mandate.attributes.merge(
            email: email, first_name: "Clark", last_name: "Kent"
          )

          partners_post endpoint, payload_hash: {mandate: mandate_attributes},
                                  headers:      {"Authorization" => access_token}

          unless response.successful?
            raise "Failed API call for mandate attributes: #{mandate_attributes.inspect}, " \
              "status: #{response.status} " \
              "response: #{response.body.inspect}"
          end
        end

        let :mandate do
          Mandate.find(JSON.parse(response.body)["mandate"]["id"])
        end

        it "returns 201 http status" do
          expect(response.status).to eq(201)
        end

        it "returns the mandate object" do
          expect(response.body)
            .to match_response_schema("partners/20170213/mandate")
        end

        it "converts mandates lead to a user" do
          expect(mandate.lead).to be_nil
          expect(mandate.user).not_to be_nil
        end

        it "sets mandate state in `in_creation`" do
          expect(mandate.in_creation?).to be_truthy
        end

        it "has correct source" do
          expect(mandate.user_or_lead.source_data["adjust"]["network"])
            .to eq(client.partnership_ident)
        end

        it "has missing data fields with partner payload" do
          expect(mandate.first_name).to eq("Clark")
          expect(mandate.last_name).to  eq("Kent")
        end
      end
    end
  end

  describe "POST /api/mandates/:id/submit_broker_mandate" do
    it_behaves_like "unathorized endpoint of the partnership api"

    let(:user)    { create(:user) }
    let(:payload) { {broker_mandate: {signature_asset: png_file, broker_mandate_asset: pdf_file}} }
    let(:mandate) do
      create(:mandate, user:        user,
                                   owner_ident: client.partnership_ident,
                                   state:       :in_creation)
    end

    context "when mandate is not accepted yet" do
      before do
        partners_post "#{endpoint}/#{mandate.id}/submit_broker_mandate",
                      payload_hash: payload,
                      headers:      {"Authorization" => access_token},
                      json:         false
      end

      it "returns mandate payload if mandate has `in_creation` state" do
        expect(response.status).to eq(201)
        expect(response.body).to match_response_schema("partners/20170213/mandate")
      end

      it "returns mandate payload if mandate has `created` state" do
        mandate.complete!
        expect(response.status).to eq(201)
        expect(response.body).to match_response_schema("partners/20170213/mandate")
      end
    end

    context "when mandate is already accepted" do
      before do
        mandate.complete!
        mandate.accept!

        partners_post "#{endpoint}/#{mandate.id}/submit_broker_mandate",
                      payload_hash: payload,
                      headers:      {"Authorization" => access_token},
                      json:         false
      end

      it "returns method_not_allowed if mandate is already accepted or passed sign up flow" do
        expect(response.status).to eq(405)
        expect(response.body).to match_response_schema("partners/20170213/error")
      end
    end
  end

  describe "GET /api/mandates/:id/portfolio" do
    let(:user) { create :user }
    let(:mandate) { create :mandate, user: user, owner_ident: client.partnership_ident }

    it_behaves_like "unathorized endpoint of the partnership api"

    context "portfolio payload" do
      before do
        partners_get "#{endpoint}/#{mandate.id}/portfolio",
                     headers: {"Authorization" => access_token}
      end

      it "returns 200" do
        expect(response.status).to eq(200)
      end

      it "returns the portfolio object" do
        expect(response.body).to match_response_schema("partners/20170213/portfolio")
      end
    end

    context "when at least one advice is exists" do
      before do
        product = create(:product, mandate: mandate)
        create(:advice, topic: product, content: "Make tests great again")

        partners_get "#{endpoint}/#{mandate.id}/portfolio",
                     headers: {"Authorization" => access_token}
      end

      it "returns 200" do
        expect(response.status).to eq(200)
      end

      it "returns the portfolio object" do
        expect(response.body).to match_response_schema("partners/20170213/portfolio")
      end

      it "has advices array inside the payload" do
        products = JSON.parse(response.body)["products"]
        advices  = products.first.fetch("advices", [])
        expect(products.count).to eq(1)
        expect(advices.count).to eq(1)
        expect(advices.first["content"].first["locale"]).to eq("de")
        expect(advices.first["content"].first["value"]).to  eq("Make tests great again")
      end
    end
  end
end
