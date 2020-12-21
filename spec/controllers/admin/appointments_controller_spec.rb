# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AppointmentsController, :integration, type: :controller do
  let(:locale)             { I18n.locale }
  let(:role)               { create(:role, permissions: Permission.where(controller: "admin/appointments")) }
  let(:admin)              { create(:admin, role: role) }
  let(:appointment)        { create(:appointment, :requested) }
  let(:appointment_lifter) { Domain::Appointments::Appointment }

  before { sign_in(admin) }

  describe "PATCH #accept" do
    before do
      allow_any_instance_of(appointment_lifter).to receive(:create_calendar_event)
      allow_any_instance_of(appointment_lifter).to receive(:send_appointment_confirmation)
      allow(controller).to receive(:send_file)
    end

    it "should update the appointment" do
      patch :accept, params: {id: appointment.id, locale: locale}
      appointment.reload
      expect(appointment.state).to eq("accepted")
    end

    it "should send the appointment email" do
      expect_any_instance_of(appointment_lifter).to receive(:send_appointment_confirmation)
      patch :accept, params: {id: appointment.id, locale: locale}
    end

    context "when already accepted" do
      let(:appointment) { create :appointment, :accepted }

      it "do not touch the appointment" do
        expect { patch :accept, params: {id: appointment.id, locale: locale} }
          .to_not change(appointment, :updated_at)
      end

      it "redirects user back" do
        patch :accept, params: {id: appointment.id, locale: locale}
        expect(response).to redirect_to admin_root_path
      end
    end
  end

  describe "GET #index" do
    context "with self service customer" do
      let(:customer) { create(:customer, :prospect) }
      let!(:customer_appointment) { create(:appointment, :requested, mandate_id: customer.id) }

      it "should fetch customer appointment" do
        get :index, params: {locale: I18n.locale}
        expect(assigns(:appointments).map(&:id)).to include(customer_appointment.id)
      end
    end

    context "with revoked mandate" do
      let!(:appointment) { create(:appointment, :requested) }
      let!(:revoked_appointment) { create(:appointment, :requested) }

      it "should render only active mandate appointments" do
        revoked_appointment.mandate.update!(state: :revoked)
        get :index, params: { locale: I18n.locale }
        expect(assigns(:appointments)).to match_array([appointment])
      end

      context "with view_revoked_mandates permission" do
        before do
          admin.permissions << create(:permission, :view_revoked_mandates)
        end

        it "should render only active mandate appointments" do
          revoked_appointment.mandate.update!(state: :revoked)
          get :index, params: { locale: I18n.locale }
          expect(assigns(:appointments)).to match_array([appointment, revoked_appointment])
        end
      end
    end
  end

  describe "GET #calendar_event" do
    it "should download the the calendar event" do
      expect_any_instance_of(appointment_lifter).to receive(:create_calendar_event)
        .and_return("")
      get :calendar_event, params: {id: appointment.id, locale: locale}
      expect(response.content_type).to eq "text/calendar"
      expect(response.headers["Content-Disposition"]).to include "#{appointment.mandate.full_name}.ics"
    end
  end
end
