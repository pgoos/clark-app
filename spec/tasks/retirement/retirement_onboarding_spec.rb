# frozen_string_literal: true

require "rails_helper"

describe "rake retirement:onboard", type: :task do
  let!(:consultant) { create(:admin, email: Settings.advisor.high_margin_admin.first) }
  let!(:mandates_group1) { create_list(:mandate, 2) }
  let!(:mandates_group2) { create_list(:mandate, 2) }

  let(:group1) { Rails.root.join("lib", "tasks", "retirement", "onboarding_groups", "group4_6.json") }
  let(:group2) { Rails.root.join("lib", "tasks", "retirement", "onboarding_groups", "group5.json") }

  before do
    allow(File).to receive(:read).with(group1).and_return({ids: mandates_group1.map(&:id)}.to_json)
    allow(File).to receive(:read).with(group2).and_return({ids: mandates_group2.map(&:id)}.to_json)
  end

  it do
    expect { task.invoke("i") }.to change(Interaction::Email, :count)
      .by(mandates_group1.count + mandates_group2.count)
  end

  it do
    task.invoke
    mandates_group1.each do |mandate|
      expect(mandate.interactions).not_to be_nil
    end

    mandates_group2.each do |mandate|
      expect(mandate.interactions).not_to be_nil
    end
  end
end
