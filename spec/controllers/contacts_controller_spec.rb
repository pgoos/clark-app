# frozen_string_literal: true
require "rails_helper"

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe ContactsController, :integration, type: :controller do
  describe "#callback" do
    subject { post :callback, params: params }

    context "when making regular callback" do
      let(:params) do
        {
          "topic"  => "Hausratversicherung",
          "name"   => "Peter Lustig",
          "email"  => "lustig@peter.de",
          "phone"  => "0190123456",
          "day"    => "12.10.2017",
          "time"   => "19:03",
          "locale" => "de"
        }
      end

      include_examples "callbacks_shared"

      it "sends an email with all information properly formatted" do
        expect { subject }.to change { ApplicationMailer.deliveries.count }.by(1)
        delivered_email = ApplicationMailer.deliveries.last.body.encoded

        expect(delivered_email).to match(params["name"])
        expect(delivered_email).to match(params["email"])
        expect(delivered_email).to match(params["phone"])
        expect(delivered_email).to match(params["time"])
        expect(delivered_email).to match(params["day"])
      end

      context "when user is in session and when user provided a different email compared to his profile" do
        let(:user)       { create(:user, :with_mandate, email: user_email) }
        before           { request.env["warden"].set_user(user, scope: :user) }
        let(:user_email) { "averydifferentemail@server.de" }

        it "sends an email to the address from his profile" do
          expect { subject }.to change { ApplicationMailer.deliveries.count }.by(1)
            .and not_change { Lead.count }
            .and not_change { Mandate.count }
          expect(ApplicationMailer.deliveries.last.body.encoded).to match(user_email)
        end
      end

      context "when making BU callback" do
        let(:params) do
          {
            "topic"       => "Berufsunfähigkeitsversicherung",
            "income"      => "upto1500",
            "monthly_pay" => "upto50",
            "first_name"  => "Dimitri",
            "last_name"   => "Kurashvili",
            "email"       => "dimakura@gmail.com",
            "phone"       => "+995 555 116776",
            "profession"  => "Software Development",
            "age"         => "36",
            "locale"      => "de"

          }
        end

        include_examples "callbacks_shared"

        it "sends an email with all information properly formatted" do
          expect { subject }.to change { ApplicationMailer.deliveries.count }.by(1)
          delivered_email = ApplicationMailer.deliveries.last.body.encoded

          expect(delivered_email).to match("bis zu 1500")
          expect(delivered_email).to match("bis zu 50")
          expect(delivered_email).to match(params["first_name"])
          expect(delivered_email).to match(params["last_name"])
          expect(delivered_email).to match(params["email"])
          expect(delivered_email).to match("995 555 116776")
          expect(delivered_email).to match(params["profession"])
          expect(delivered_email).to match(params["age"])
        end

        context "when BU category exists in DB" do
          before { create :category, name: "Berufsunfähigkeitsversicherung" }

          it "creates a BU opportunity" do
            expect { subject }.to change { ApplicationMailer.deliveries.count }.by(1)
              .and change { Opportunity.count }.by(1)
          end
        end

        context "when no BU category exists in DB" do
          it "creates no BU opportunity but still sends the email" do
            expect { subject }.to change { ApplicationMailer.deliveries.count }.by(1)
          end
        end

        context "when user is in session and when user provided a different email compared to his profile" do
          let(:user)       { create(:user, :with_mandate, email: user_email) }
          before           { request.env["warden"].set_user(user, scope: :user) }
          let(:user_email) { "averydifferentemail@server.de" }

          it "sends an email to this different address" do
            expect { subject }.to change { ApplicationMailer.deliveries.count }.by(1)
              .and not_change { Lead.count }
              .and not_change { Mandate.count }
            expect(ApplicationMailer.deliveries.last.body.encoded).to match(params["email"])
          end
        end
      end
    end
  end
end
