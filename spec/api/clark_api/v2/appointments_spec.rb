# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Appointments, :integration do
  include AppointmentDateHelpers
  include Rails.application.routes.url_helpers

  before do
    @configured_locale = I18n.locale
    I18n.locale = :de

    @site = Comfy::Cms::Site.create(
      label: "de", identifier: "de", hostname: TestHost.host_and_port,
      path: "de", locale: "de"
    )

    # Do not try to send out mails on every request
    allow(OfferMailer).to receive_message_chain("offer_appointment_request.deliver_now")
    allow(OfferMailer).to receive_message_chain(
      "offer_appointment_confirmation_phone_call.deliver_now"
    )
  end

  after do
    I18n.locale = @configured_locale
    @site.destroy
  end

  Time.use_zone("Europe/Berlin") do
    let(:cockpit) { create(:retirement_cockpit) }
    let(:mandate) { create(:mandate, retirement_cockpit: cockpit) }
    let(:user) { create(:user, mandate: mandate) }
    let(:appointment_hour) { 9 }
    let!(:appointment_time_param) { "#{appointment_hour}:00" }
    let(:expected_appointment_start) do
      utc_offset = UtcOffsetCalculator.utc_day_end_offset_for_date(next_monday_thats_not_holiday)
      DateTime.strptime(
        "#{next_monday_thats_not_holiday} #{appointment_time_param} +#{utc_offset}",
        "%Y-%m-%d %H:%M %z"
      ).utc
    end
    let(:appointment_db_stamp) do
      next_non_hollyday_after_monday.strftime("%Y-%m-%d ") + ("%02d:00:00" % appointment_hour)
    end
    def assert_appointment(appointment, call_type_check, expected_mandate, appointable,
                           phone_number)
      unless %i[phone? video?].include?(call_type_check)
        raise "cannot test this call_type: #{call_type_check}"
      end
      expect(appointment.starts).to eq(expected_appointment_start)
      expect(appointment.send(call_type_check)).to be_truthy
      expect(appointment.mandate).to eq(expected_mandate)
      expect(appointment.appointable).to eq(appointable)
      expect(appointment.mandate.phone).to eq(PhonyRails.normalize_number(phone_number, country_code: :DE))
    end

    let(:opportunity) { create(:opportunity_with_offer, mandate: user.mandate) }

    context "POST /api/appointments" do
      let(:params) do
        {
          timeslot:         appointment_time_param,
          # We will get a string from the clients!
          date:             next_non_hollyday_after_monday.strftime("%d.%m.%Y"),
          call_type:        "phone",
          phone:            "069 153 229 339",
          appointable_type: Opportunity.name,
          appointable_id:   opportunity.id
        }
      end

      context "when logged in" do
        before do
          login_as(user, scope: :user)
        end

        context "validations" do
          it "returns 201 if all params are there" do
            json_post_v2 "/api/appointments", params
            expect(response.status).to eq(201)
          end

          it "returns appointment" do
            json_post_v2 "/api/appointments", params

            appointment = user.mandate.appointments.last
            parsed_response = JSON.parse(response.body)

            expect(parsed_response["id"]).to eq(appointment.id)
          end

          %i[timeslot date call_type phone].each do |attribute|
            it "returns 400 if param #{attribute} is missing" do
              json_post_v2 "/api/appointments", params.except(attribute)
              expect(response.status).to eq(400)
            end
          end

          it "returns 400 if date is in the past" do
            json_post_v2 "/api/appointments",
                         params.merge(date: last_monday_thats_not_holiday.strftime("%d.%m.%Y"))
            expect(response.status).to eq(400)
            expect(json_response.errors.api.date)
              .to include(I18n.t("grape.errors.messages.date_in_future"))
          end

          it "returns 400 if date is today" do
            json_post_v2 "/api/appointments",
                         params.merge(date: date_outside_weekend(Time.zone.today).strftime("%d.%m.%Y"))
            expect(response.status).to eq(400)
            expect(json_response.errors.api.date)
              .to include(I18n.t("grape.errors.messages.date_in_future"))
          end

          it "returns 201 if date is a saturday and not holiday" do
            date = next_saturday # Cannot really use a Next non-holiday Satday because for 10 days timeframe
            json_post_v2 "/api/appointments",
                         params.merge(date: next_saturday.strftime("%d.%m.%Y"))

            if holiday?(date)
              expect(response.status).to eq(400)
              expect(json_response.errors.api.date).to include(I18n.t("grape.errors.messages.date_is_not_holiday"))
            else
              expect(response.status).to eq(201)
            end
          end

          it "returns 400 if date is a sunday" do
            json_post_v2 "/api/appointments",
                         params.merge(date: next_sunday.strftime("%d.%m.%Y"))
            expect(response.status).to eq(400)
            expect(json_response.errors.api.date)
              .to include(I18n.t("grape.errors.messages.date_is_not_sunday"))
          end

          it "returns 400 if date is a holiday" do
            next_holiday_in_a_month = next_holiday_in_month
            skip if next_holiday_in_a_month.nil?
            json_post_v2 "/api/appointments",
                         params.merge(date: next_holiday_in_a_month.strftime("%d.%m.%Y"))

            expect(response.status).to eq(400)
            expect(json_response.errors.date.self)
              .to include(I18n.t("grape.errors.messages.date_is_not_holiday"))
          end

          it "returns 400 if date is more than a month in the future" do
            date = not_holiday_date_next_month.strftime("%d.%m.%Y")
            payload = params.merge(date: date)
            json_post_v2 "/api/appointments", payload

            expect(response.status).to eq(400)

            error_key = "activerecord.errors.models.appointment.starts.too_late"
            expect(json_response.errors.appointment.starts)
              .to include(I18n.t(error_key))
          end

          it "returns 400 if timeslot intersects another appointment" do
            create(
              :appointment,
              starts: appointment_db_stamp,
              ends: nil,
              mandate: mandate,
              appointable: opportunity
            )
            json_post_v2 "/api/appointments", params

            expect(response.status).to eq(400)

            error_key = "activerecord.errors.models.appointment.starts.intersect"
            expect(json_response.errors.appointment.starts)
              .to include(I18n.t(error_key))
          end

          it "returns 400 if the phone is not valid" do
            json_post_v2 "/api/appointments", params.merge(phone: "this is not a phone number")
            expect(response.status).to eq(400)

            # TODO: find the place, where the error message is created and use i18n
            phone_error_expected = "Keine gültige Telefonnummer."
            phone_errors = json_response.errors.mandate.phone
            expect(phone_errors).to include(phone_error_expected)
          end

          it "returns 400 if the phone is empty" do
            json_post_v2 "/api/appointments", params.merge(phone: "")
            expect(response.status).to eq(400)
            phone_error_expected = "Bitte gebe deine Telefonnummer ein."
            phone_errors = json_response.errors.api.phone
            expect(phone_errors).to include(phone_error_expected)
          end

          it "returns 400 if date is empty" do
            payload = params.merge(date: "")
            json_post_v2 "/api/appointments", payload

            expect(response.status).to eq(400)
            date_error_expected = "Bitte wähle einen Termin."
            date_errors = json_response.errors.api.date
            expect(date_errors).to include(date_error_expected)
          end

          it "returns 400 if timeslot is empty" do
            payload = params.merge(timeslot: "")
            json_post_v2 "/api/appointments", payload

            expect(response.status).to eq(400)
            timeslot_error_expected = "Bitte wähle eine Uhrzeit."
            timeslot_errors = json_response.errors.api.timeslot
            expect(timeslot_errors).to include(timeslot_error_expected)
          end
        end

        context "making a generic appointment" do
          # define some custom params for a generic appointment
          let(:params) do
            {
              timeslot:  appointment_time_param,
              date:      next_monday_thats_not_holiday,
              call_type: "phone",
              phone:     "069 153 229 339",
              user:      user.id
            }
          end

          let(:mailer_params) do
            admin_mandate_url = admin_mandate_url(:de, user.mandate, host: TestHost.host_and_port)
            {
              day:                        next_monday_thats_not_holiday,
              time:                       appointment_time_param,
              phone:                      "069 153 229 339",
              mandate:                    admin_mandate_url,
              name:                       user.mandate.full_name,
              email:                      user.email,
              topic:                      "Allgemeine Terminanfrage",
              retirement_score_requested: nil,
              method_of_contact: ""
            }
          end

          it "sends out the appointment request to the consultant" do
            expect(ApplicationMailer).to receive(:callback_with_data).with(mailer_params)
                                                                     .and_return(ActionMailer::Base::NullMail.new)

            json_post_v2 "/api/appointments", params

            expect(response.status).to eq(201)
          end

          context "when retirement-related appointment" do
            let(:mailer) { double(ApplicationMailer) }
            let(:params) do
              {
                timeslot:  appointment_time_param,
                date:      next_monday_thats_not_holiday,
                call_type: "phone",
                phone:     "069 153 229 339",
                user:      user.id,
                appointable_type: "Retirement::Cockpit",
                appointable_id: cockpit.id
              }
            end
            let(:mailer_params) do
              admin_mandate_url = admin_mandate_url(:de, user.mandate, host: TestHost.host_and_port)
              {
                day:                        next_monday_thats_not_holiday,
                time:                       appointment_time_param,
                phone:                      "069 153 229 339",
                mandate:                    admin_mandate_url,
                name:                       user.mandate.full_name,
                email:                      user.email,
                topic:                      "Retirement Score Improvement Termin",
                retirement_score_requested: nil,
                method_of_contact: ""
              }
            end

            around do |example|
              # If this line is removed the tests will break when you have a holiday on monday
              # https://clarkteam.atlassian.net/browse/JCLARK-47827
              # TODO: Refactor this test to not do this logic anymore
              # https://clarkteam.atlassian.net/browse/JCLARK-47829
              Timecop.freeze(Date.new(2019, 4, 8)) do
                example.call
              end
            end

            before do
              allow(ApplicationMailer).to receive(:callback_with_data).with(mailer_params) { mailer }
              allow(mailer).to receive(:deliver_now)

              json_post_v2 "/api/appointments", params
            end

            it { expect(mailer).to have_received(:deliver_now) }
          end

          it "does not create an appointment" do
            allow(ApplicationMailer).to receive(:callback_with_data).with(mailer_params)
                                                                    .and_return(ActionMailer::Base::NullMail.new)

            expect {
              json_post_v2 "/api/appointments", params
            }.to change { Appointment.count }.by(0)
          end
        end

        context "making an appintment with additional contact information" do
          let(:params) do
            {
              timeslot:  appointment_time_param,
              date:      next_monday_thats_not_holiday,
              call_type: "phone",
              phone:     "069 153 229 339",
              user:      user.id,
              method_of_contact: 'phone'
            }
          end

          let(:mailer_params) do
            admin_mandate_url = admin_mandate_url(:de, user.mandate, host: TestHost.host_and_port)
            {
              day:                        next_monday_thats_not_holiday,
              time:                       appointment_time_param,
              phone:                      "069 153 229 339",
              mandate:                    admin_mandate_url,
              name:                       user.mandate.full_name,
              email:                      user.email,
              topic:                      "Allgemeine Terminanfrage",
              retirement_score_requested: nil,
              method_of_contact: I18n.t("attribute_domains.appointments.contact_method.phone")
            }
          end

          it "sends out the appointment request to the consultant, including the method of contact" do
            expect(ApplicationMailer).to receive(:callback_with_data).with(mailer_params)
                                                                     .and_return(ActionMailer::Base::NullMail.new)

            json_post_v2 "/api/appointments", params

            expect(response.status).to eq(201)
          end
        end

        context "making an appointment with a related object" do
          let(:params) do
            {
              timeslot:         appointment_time_param,
              date:             next_non_hollyday_after_monday,
              call_type:        "phone",
              phone:            "069 153 229 339",
              user:             user.id,
              appointable_type: Opportunity.name,
              appointable_id:   opportunity.id
            }
          end

          let(:mailer_params) do
            admin_opportunity_url = admin_opportunity_url(
              :de, opportunity, host: TestHost.host_and_port
            )
            admin_url = admin_mandate_url(:de, user.mandate,
                                          host: TestHost.host_and_port)

            topic = "Gelegenheit: #{admin_opportunity_url}"
            {
              day:                        next_non_hollyday_after_monday,
              time:                       appointment_time_param,
              phone:                      "069 153 229 339",
              mandate:                    admin_url,
              name:                       user.mandate.full_name,
              email:                      user.email,
              topic:                      topic,
              retirement_score_requested: nil,
              method_of_contact: ""
            }
          end

          let(:expected_appointment_start) do
            date = next_non_hollyday_after_monday
            utc_offset = UtcOffsetCalculator.utc_day_end_offset_for_date(date)

            DateTime.strptime(
              "#{next_non_hollyday_after_monday} #{appointment_time_param} +#{utc_offset}",
              "%Y-%m-%d %H:%M %z"
            ).utc
          end

          it "does send out an appointment request" do
            expect(ApplicationMailer).to receive(:callback_with_data).with(mailer_params)
                                                                     .and_return(ActionMailer::Base::NullMail.new)

            json_post_v2 "/api/appointments", params

            expect(response.status).to eq(201)
          end

          it "creates an appointment entity" do
            allow(ApplicationMailer).to receive(:callback_with_data).with(mailer_params)
                                                                    .and_return(ActionMailer::Base::NullMail.new)

            expect {
              json_post_v2 "/api/appointments", params
            }.to change { Appointment.count }.by(1)

            assert_appointment(Appointment.last, :phone?, user.mandate, opportunity, params[:phone])
          end

          it "accepts a timeslot with start and end" do
            timeslot = "10:00 - 12:00"
            params[:timeslot] = timeslot
            mailer_params[:time] = timeslot

            allow(ApplicationMailer).to receive(:callback_with_data).with(mailer_params)
                                                                    .and_return(ActionMailer::Base::NullMail.new)

            expect {
              json_post_v2 "/api/appointments", params
            }.to change { Appointment.count }.by(1)

            expect(response.status).to eq(201)

            appointment = Appointment.last
            expect(appointment.starts.strftime("%H:%M")).to eq("10:00")
            expect(appointment.ends.strftime("%H:%M")).to eq("12:00")
          end
        end

        context "when making an appointment for an offer" do
          let(:expected_appointment_start) do
            date = next_non_hollyday_after_monday
            utc_offset = UtcOffsetCalculator.utc_day_end_offset_for_date(date)
            DateTime.strptime(
              "#{next_non_hollyday_after_monday} #{appointment_time_param} +#{utc_offset}",
              "%Y-%m-%d %H:%M %z"
            ).utc
          end

          before do
            opportunity.offer.update_attributes(state: "accepted")
          end

          def appointment_data(call_type)
            expected_mail = mail_data(call_type)
            expected_mail.merge(
              "offer_id"         => opportunity.offer.id
            ).with_indifferent_access
          end

          def mail_data(call_type)
            date = next_non_hollyday_after_monday.strftime("%d.%m.%Y").to_date
            {
              "phone"                      => "069 153 229 339",
              "appointable_type"           => nil,
              "appointable_id"             => nil,
              "timeslot"                   => appointment_time_param,
              "date"                       => date,
              "call_type"                  => call_type,
              "retirement_score_requested" => nil,
              "method_of_contact"          => nil
            }.with_indifferent_access
          end

          it "sends out the appointment request to the consultant" do
            expect(OfferMailer).to receive(:offer_appointment_request)
              .with(opportunity.offer, mail_data("phone"))
              .and_return(ActionMailer::Base::NullMail.new)
            json_post_v2 "/api/appointments", appointment_data("phone")

            expect(response.status).to eq(201)
          end

          it "creates an appointment with the call type phone" do
            allow(OfferMailer).to receive(:offer_appointment_request)
              .with(opportunity.offer, mail_data("phone"))
              .and_return(ActionMailer::Base::NullMail.new)
            expect {
              json_post_v2 "/api/appointments", appointment_data("phone")
            }.to change { Appointment.count }.by(1)

            assert_appointment(Appointment.last, :phone?, user.mandate, opportunity, params[:phone])
          end

          it "creates an appointment with the call type video" do
            allow(OfferMailer).to receive(:offer_appointment_request)
              .with(opportunity.offer, mail_data("video"))
              .and_return(ActionMailer::Base::NullMail.new)
            params["call_type"] = "video"

            expect {
              json_post_v2 "/api/appointments", appointment_data("video")
            }.to change { Appointment.count }.by(1)

            assert_appointment(Appointment.last, :video?, user.mandate, opportunity, params[:phone])
          end
        end
      end

      it "returns 401 if the user is not singed in" do
        json_post_v2 "/api/appointments", params
        expect(response.status).to eq(401)
      end
    end
  end
end
