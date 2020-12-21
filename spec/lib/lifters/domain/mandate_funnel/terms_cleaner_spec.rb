# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::MandateFunnel::TermsCleaner, :integration do
  describe "#call" do
    let(:mandate) do
      create(
        :mandate,
        :wizard_confirmed,
        skip_signature_validation: true,
        tos_accepted_at: Time.zone.now,
        created_at: before_date.ago(1.day)
      )
    end

    let(:not_touched_mandate) do
      create(
        :mandate,
        :wizard_confirmed,
        skip_signature_validation: true,
        tos_accepted_at: before_date,
        created_at: now
      )
    end

    let(:now) { Date.new(2018, 11, 13) }
    let(:before_date) { now.ago(10.days) }

    before do
      Timecop.freeze(now)
      mandate
      not_touched_mandate
      call
    end

    after do
      Timecop.return
    end

    context "when before date is provided" do
      let(:call) { subject.call(before: before_date) }

      it "doesn't set an error" do
        expect(subject).not_to be_errors
      end

      it "clean tos confirmation only for before date mandate" do
        expect(mandate.reload.tos_accepted).to eq(false)
        expect(not_touched_mandate.reload.tos_accepted).to eq(true)
      end
    end

    context "when before date isn't provided" do
      let(:call) { subject.call(before: nil) }

      it "doesn't set an error" do
        expect(subject).not_to be_errors
      end

      it "clean tos confirmation" do
        expect(mandate.reload.tos_accepted).to eq(false)
        expect(not_touched_mandate.reload.tos_accepted).to eq(false)
      end
    end
  end
end
