# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Profile::Salary::Create do
  subject { described_class.new(mandate, new_salary) }

  describe "#call" do
    let(:mandate)          { create(:mandate) }
    let(:new_salary)       { 5_000_000 }

    before { create(:profile_property, identifier: "text_brttnkmmn_bad238") }

    it { expect { subject.call }.to change(ProfileDatum, :count).by(1) }
  end
end
