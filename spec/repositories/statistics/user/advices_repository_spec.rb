# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statistics::User::AdvicesRepository, :integration do
  subject { described_class.new(mandate: mandate) }

  let(:user) do
    create(
      :user,
      last_sign_in_at: last_sign_in_at
    )
  end
  let(:mandate) { create(:mandate, user: user) }

  let(:now) { Time.zone.parse("2010-01-03 10:00:00") }
  let(:last_sign_in_at) { Time.zone.parse("2010-01-03 00:00:00") }
  let(:after_sign_in) { Time.zone.parse("2010-01-03 01:00:00") }

  let(:advice) do
    create(
      :advice,
      mandate: mandate,
      created_at: advice_created_at
    )
  end

  before { Timecop.freeze(now) }

  after { Timecop.return }

  context "with advice created in :last_login range" do
    let(:advice_created_at) { after_sign_in }

    it "returns the advice" do
      expect(subject.created_on_products(period: :last_login)).to eq([advice])
    end
  end

  context "with advice created before :last_login range" do
    let(:advice_created_at) { before_sign_in }

    it "returns no advice" do
      expect(subject.created_on_products(period: :last_login)).to eq([])
    end
  end
end
