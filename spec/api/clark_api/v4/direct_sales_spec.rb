# frozen_string_literal: true

require "rails_helper"

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe ClarkAPI::V4::DirectSales, :integration do
  context "POST /api/mailings/directsales" do
    subject { json_post_v4 "/api/directsales/checkout", params }

    let(:mandatory_params) do
      {
        customer: {
          email: "test@clark.de",
          iban: "DE89 3704 0044 0532 0130 00",
          first_name: "Tim",
          last_name: "Berners-Lee",
          salutation: "Herr",
          title: "Dr. ",
          birthdate: "8.6.1955",
          telephone: ClarkFaker::PhoneNumber.phone_number,
          postal_code: "02139",
          city: "Cambridge MA",
          street: "Vassar Street",
          house_number: "32",
          insurance: {
            begins: "8.6.1955",
            deductible: true,
            payment_interval: "yearly",
            animal: {
              date_of_birth: "8.8.1933",
              name: "whatevaa",
              id: "23",
              sex: "male"
            }
          },
          tracking: {
            utm_source: "somthing",
            utm_medium: "something else"
          }
        }
      }
    end

    before do
      allow(ServiceMailer).to receive_message_chain(:direct_sales_sale, :deliver_now).and_return(double)
      allow(DirectSalesMailer).to receive_message_chain(:insurance_purchase_confirmation, :deliver_now)
        .and_return(double)
    end

    context "when mandatory parameters are given" do
      let(:params) { mandatory_params }

      it "sends email with form data to Clark employee" do
        subject
        expect(response.status).to eq(201)
      end
    end

    context "when mandatory params are missing" do
      let(:params) { nil }

      it "does not send an email and returns presence validation errors" do
        subject
        expect(response.status).to eq(400)
        expect(response.body).to match("errors")
        mandatory_params[:customer].keys.each do |param|
          next if param == :title
          expect(response.body).to match(param.to_s)
        end
      end
    end

    context "iban param" do
      context "when iban is invalid" do
        let(:params) do
          mandatory_params[:customer].merge!(iban: "invalid_iban")
          mandatory_params
        end

        it "does not send an email and returns validation errors" do
          json_post_v4 "/api/directsales/checkout", params
          expect(response.status).to eq(400)
          expect(response.body).to match("errors")
          expect(response.body).to match("iban")
        end
      end

      context "when IBAN is in valid format" do
        before do
          allow(Settings).to(
            receive_message_chain("iban.allowed_countries")
              .and_return(allowed_countries)
          )
        end

        let(:params) do
          mandatory_params[:customer].merge!(iban: "AT61 1904 3002 3457 3201")
          mandatory_params
        end

        context "when country is allowed" do
          let(:allowed_countries) { { AT: true } }

          it "sends email with form data to Clark employee" do
            subject
            expect(response.status).to eq(201)
          end
        end

        context "when country isn't allowed" do
          let(:allowed_countries) { { DE: true } }

          it "does not send an email and returns validation errors" do
            subject
            expect(response.status).to eq(400)
            expect(response.body).to match("errors")
            expect(response.body).to match("iban")
          end
        end
      end
    end

    context "when zipcode is invalaid" do
      let(:params) { mandatory_params[:customer].merge!(postal_code: "invalid_iban") }

      it "does not send an email and returns validation errors" do
        subject
        expect(response.status).to eq(400)
        expect(response.body).to match("errors")
        expect(response.body).to match("postal_code")
      end
    end

    context "when lead is in session and other lead with given email already exists" do
      let!(:lead) { create(:lead, mandate: create(:mandate)) }
      let!(:other_lead) { create(:lead, email: "timbl@w3.org", mandate: create(:mandate)) }
      let(:params) { mandatory_params }

      before { login_as(lead, scope: :lead) }

      it "updates the lead's email and subscription status" do
        expect { subject }.to change { lead.reload.email }
        expect(response.status).to eq(201)
      end
    end

    context "when empty current mandate is availalbe from session" do
      let!(:lead) { create(:lead, mandate: mandate) }
      let!(:mandate) {
        create(:mandate, first_name: nil,
                         last_name: nil,
                         birthdate: nil,
                         phone: nil,
                         active_address: nil)
      }
      let(:params) { mandatory_params }

      before { login_as(lead, scope: :lead) }

      it "updates the mandate" do
        expect {
          subject
        }.to change {
          mandate.reload.first_name
        }.to(params[:customer][:first_name])
          .and change(mandate, :last_name)
          .to(params[:customer][:last_name])
          .and change(mandate, :birthdate)
          .to(DateTime.parse(params[:customer][:birthdate]))
          .and change(mandate, :phone)
          .to("+49#{params[:customer][:telephone]}")
          .and change(mandate, :zipcode)
          .to(params[:customer][:postal_code])
          .and change(mandate, :city)
          .to(params[:customer][:city])
          .and change(mandate, :street)
          .to(params[:customer][:street])
          .and change(mandate, :house_number)
          .to(params[:customer][:house_number])

        expect(response.status).to eq(201)
      end
    end

    context "when current mandate is availalbe from session but has data already" do
      let!(:lead) { create(:lead, mandate: mandate) }
      let!(:address) do
        create(
          :address,
          zipcode: "12345",
          city: "Berlin",
          street: "RL",
          house_number: "2",
          active: true
        )
      end

      let!(:mandate) do
        create(:mandate, first_name: "some_first_name",
                         last_name: "some_last_name",
                         phone: "+49#{ClarkFaker::PhoneNumber.phone_number}",
                         birthdate: DateTime.parse("11.11.1911"),
                         active_address: address)
      end

      let(:params) { mandatory_params }

      before { login_as(lead, scope: :lead) }

      it "does not update the mandate" do
        expect { subject }.to not_change { mandate.reload.first_name }
          .and not_change { mandate.last_name }
          .and not_change { mandate.birthdate }
          .and not_change { mandate.phone }
          .and not_change { mandate.zipcode }
          .and not_change { mandate.city }
          .and not_change { mandate.street }
          .and not_change { mandate.house_number }

        expect(response.status).to eq(201)
      end
    end

    context "e-mail validation" do
      let(:params) { mandatory_params }

      context "does not send an email when email is invalid" do
        it "missing @" do
          params[:customer][:email] = "notemail.com"
          subject
          expect(response.status).to eq(400)
          expect(response.body).to match("errors")
        end
        it "incomplete email" do
          params[:customer][:email] = "email@"
          subject
          expect(response.status).to eq(400)
          expect(response.body).to match("errors")
        end
        it "missing email ending" do
          params[:customer][:email] = "email@d"
          subject
          expect(response.status).to eq(400)
          expect(response.body).to match("errors")
        end
        it "missing email domain" do
          params[:customer][:email] = "email@d."
          subject
          expect(response.status).to eq(400)
          expect(response.body).to match("errors")
        end
      end

      it "send an email when email is valid" do
        subject
        expect(response.status).to eq(201)
      end
    end
  end

  context "POST /api/mailings/saleopportunity" do
    subject { json_post_v4 "/api/directsales/saleopportunity", params }

    let(:mandatory_params) do
      {
        customer: {
          email: "test@clark.de",
          first_name: "Tim",
          last_name: "Berners-Lee",
          telephone: ClarkFaker::PhoneNumber.phone_number,
          tracking: {
            utm_source: "somthing",
            utm_medium: "something else",
            landing_page: "some landing page"
          }
        }
      }
    end

    before do
      allow(ServiceMailer).to receive_message_chain(:direct_sales_sale, :deliver_now).and_return(double)
    end

    context "when mandatory parameters are given" do
      let(:params) { mandatory_params }

      it "sends email with form data to Clark employee" do
        subject
        expect(response.status).to eq(201)
      end
    end

    context "when mandatory params are missing" do
      let(:params) { nil }

      it "does not send an email and returns presence validation errors" do
        subject
        expect(response.status).to eq(400)
        expect(response.body).to match("errors")
        mandatory_params[:customer].keys.each do |param|
          next if param == :title
          expect(response.body).to match(param.to_s)
        end
      end
    end

    context "e-mail validation" do
      let(:params) { mandatory_params }

      context "does not send an email when email is invalid" do
        it "missing @" do
          params[:customer][:email] = "notemail.com"
          subject
          expect(response.status).to eq(400)
          expect(response.body).to match("errors")
        end
        it "incomplete email" do
          params[:customer][:email] = "email@"
          subject
          expect(response.status).to eq(400)
          expect(response.body).to match("errors")
        end
        it "missing email ending" do
          params[:customer][:email] = "email@d"
          subject
          expect(response.status).to eq(400)
          expect(response.body).to match("errors")
        end
        it "missing email domain" do
          params[:customer][:email] = "email@d."
          subject
          expect(response.status).to eq(400)
          expect(response.body).to match("errors")
        end
      end

      it "send an email when email is valid" do
        subject
        expect(response.status).to eq(201)
      end
    end

    context "when empty current mandate is availalbe from session" do
      let!(:lead) { create(:lead, mandate: mandate) }
      let!(:mandate) {
        create(:mandate, first_name: nil,
                         last_name: nil,
                         phone: nil)
      }
      let(:params) { mandatory_params }

      before { login_as(lead, scope: :lead) }

      it "updates the mandate" do
        expect { subject }.to change { mandate.reload.first_name }.to(params[:customer][:first_name])
                                                                  .and change(mandate, :last_name).to(params[:customer][:last_name])
                                                                                                  .and change(mandate, :phone).to("+49#{params[:customer][:telephone]}")

        expect(response.status).to eq(201)
      end
    end

    context "when current mandate is availalbe from session but has data already" do
      let!(:lead) { create(:lead, mandate: mandate) }

      let!(:mandate) do
        create(:mandate, first_name: "some_first_name",
                         last_name: "some_last_name",
                         phone: ClarkFaker::PhoneNumber.phone_number)
      end

      let(:params) { mandatory_params }

      before { login_as(lead, scope: :lead) }

      it "does not update the mandate" do
        expect { subject }.to not_change { mandate.reload.first_name }
          .and not_change { mandate.last_name }

        expect(response.status).to eq(201)
      end
    end

    context "when lead is in session and other lead with given email already exists" do
      let!(:lead) { create(:lead, mandate: create(:mandate)) }
      let!(:other_lead) { create(:lead, email: "timbl@w3.org", mandate: create(:mandate)) }
      let(:params) { mandatory_params }

      before { login_as(lead, scope: :lead) }

      it "updates the lead's email and subscription status" do
        expect { subject }.to change { lead.reload.email }
        expect(response.status).to eq(201)
      end
    end
  end
end
