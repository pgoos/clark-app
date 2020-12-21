# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::MandateFunnel::Conversion do
  let(:mandate) { instance_double(Mandate, lead: lead, state: :in_creation) }

  describe "#execute!" do
    subject { described_class.new(mandate) }

    let(:user) { instance_double(User) }

    context "when lead is activated" do
      let(:lead)     { build_stubbed(:lead, email: "test@example.com", state: "active") }
      let(:password) { "Test1234" }

      before do
        allow_any_instance_of(PasswordGenerator).to receive(:generate_random_pw_delegate).and_return(password)
        allow(User).to receive(:create!).with(email: lead.email, password: password).and_return(user)
        allow(User).to receive(:find_by).with(email: lead.email).and_return(nil)
        allow(DeviceLeadConverter).to receive(:convert_device_lead_to_user).with(lead, user)
        allow(mandate).to receive(:in_creation?).and_return(true)

        subject.execute!
      end

      it "creates user with e-mail and password" do
        expect(User).to have_received(:create!)
      end

      it "calls DeviceLeadConverter.convert_device_lead_to_user" do
        expect(DeviceLeadConverter).to have_received(:convert_device_lead_to_user)
      end
    end

    context "when user exists" do
      let(:lead) { build_stubbed(:lead, email: "test@example.com", state: "active") }
      let(:exists_user) { build_stubbed(:user, email: lead.email) }
      let(:password) { "Test1234" }

      before do
        allow(User).to receive(:find_by).with(email: lead.email).and_return(exists_user)
        allow(DeviceLeadConverter).to receive(:convert_device_lead_to_user).with(lead, exists_user)
        allow(mandate).to receive(:in_creation?).and_return(true)

        subject.execute!
      end

      it "uses exists user" do
        expect(User).not_to receive(:create!)
      end

      it "calls DeviceLeadConverter.convert_device_lead_to_user" do
        expect(DeviceLeadConverter).to have_received(:convert_device_lead_to_user)
      end
    end

    context "validations" do
      context "when lead is nil" do
        let(:lead) { nil }

        it "raises no lead error" do
          expect { subject.execute! }.to raise_error(StandardError, "no lead")
        end
      end

      context "when mandate is not in the convertible states" do
        let(:lead) { build_stubbed(:lead, email: "lead@clark.de") }

        before do
          allow(lead).to receive(:mandate).and_return(mandate)
          allow(mandate).to receive(:state).and_return(:rejected)
        end

        it "raises invalid lead error" do
          expect { subject.execute! }.to raise_error(StandardError, I18n.t("admin.lead.convert.state"))
        end
      end
    end
  end
end
