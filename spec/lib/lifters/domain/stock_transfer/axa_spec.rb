# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::StockTransfer::Axa do
  subject { described_class.new(transfer_command: transfer_command) }

  let(:transfer_command) { n_instance_double(described_class::TransferMandates, "transfer_command") }

  it "should provide a batch size" do
    expect(subject.batch_size).to be_a(Integer)
  end

  it "should provide the entity's class" do
    expect(subject.entity_class.try(:new)).to be_an(ApplicationRecord)
  end

  context "when querying the DB", :integration do
    let(:axa_company_idents) do
      [
        "axad46bc626", # AXA
        "dbv6cfe17c5", # DVB
        "deutse1ed6e"  # Deutsche Ärzteversicherung
      ]
    end
    let(:axa_companies) { axa_company_idents.map { |ident| create(:company, ident: ident) } }
    let(:sample_category) { create(:category) }
    let(:matching_inquiry_states) { %i[pending] }

    before do
      axa_companies
      sample_category
    end

    it "should provide the company names" do
      expect(subject.company_names).to eq(axa_companies.map(&:name).sort)
    end

    describe "#new_entities" do
      it "returns an empty collection, if no mandates are found" do
        expect(subject.new_entities).to be_empty
      end

      it "returns all accepted mandates with axa inquiries in states in_creation or pending, with categories" do
        expected_mapping = {}
        axa_companies.each do |company|
          mandate = create(:mandate, :accepted)
          expected_mapping[mandate] ||= []

          inquiry = create(:inquiry, company: company, mandate: mandate) # state will be pending
          expected_mapping[mandate] << create(:inquiry_category, category: sample_category, inquiry: inquiry)
        end

        # inquiry states to be excluded:
        Inquiry.state_machine.states.keys.except(*matching_inquiry_states).each do |state|
          mandate = create(:mandate, :accepted)
          inquiry = create(:inquiry, company: axa_companies.first, mandate: mandate)
          inquiry.update!(state: state)
          create(:inquiry_category, category: sample_category, inquiry: inquiry)
        end

        # exclude, if there are no inquiry categories
        create(:inquiry, company: axa_companies.first, state: :in_creation, mandate: create(:mandate, :accepted))

        # exclude, if all inquiry categories are in a finished state
        InquiryCategory.state_machine.states.keys.except(:in_progress).each do |state|
          mandate = create(:mandate, :accepted)
          inquiry = create(:inquiry, company: axa_companies.first, mandate: mandate)
          create(:inquiry_category, category: sample_category, inquiry: inquiry, state: state)
        end

        # exclude, if the mandate is not accepted
        Mandate.state_machine.states.keys.except(:accepted) do |state|
          mandate = create(:mandate, state: state)
          inquiry = create(:inquiry, company: axa_companies.first, mandate: mandate, state: :pending)
          create(:inquiry_category, category: sample_category, inquiry: inquiry)
        end

        expect(subject.new_entities).to eq(expected_mapping)
      end
    end
  end

  describe "#request_stock_transfer" do
    let(:mandates) { [] }
    let(:mandate1) { n_instance_double(Mandate, "mandate1") }
    let(:inquiry1) { n_instance_double(Inquiry, "inquiry1") }
    let(:mandate2) { n_instance_double(Mandate, "mandate2") }
    let(:inquiry2) { n_instance_double(Inquiry, "inquiry2") }

    let(:inquiries) { [] }
    let(:transfer_result) { {transferred_entities: [], errors: {}} }
    let(:companies) { [n_instance_double(Company, "sample_axa_company")] }

    before do
      allow(Company).to receive(:where).with(ident: described_class.company_idents).and_return(companies)
      allow(transfer_command)
        .to receive(:call)
        .with(mandates, companies)
        .and_yield(inquiries, transfer_result[:errors])
        .and_return(transfer_result)
    end

    [nil, []].each do |nothing|
      it "should do nothing, if #{nothing.class.name} is passed" do
        expect(transfer_command).not_to receive(:call).with(any_args)
        subject.request_stock_transfer(nothing)
      end

      it "should return an empty result, if #{nothing.class.name} is passed" do
        expect(subject.request_stock_transfer(nothing)).to eq(transfer_result)
      end
    end

    it "should fail, if more mandates than the batch size are given" do
      too_many = []
      (subject.batch_size + 1).times { |i| too_many << n_instance_double(Mandate, "too_many_mandates_#{i}") }
      error_message = I18n.t(
        "stock_transfer_direct_agreements.request_transfer.too_many",
        count: too_many.count,
        batch_size: subject.batch_size
      )
      expect(error_message).not_to match(/translation missing/)
      expect { subject.request_stock_transfer(too_many) }.to raise_error(error_message)
    end

    context "with input" do
      before do
        mandates << mandate1 << mandate2
        inquiries << inquiry1 << inquiry2
        inquiries.each do |i|
          allow(i).to receive(:contact!).and_return(true)
        end
      end

      it "should call the transfer for mandates" do
        expect(transfer_command)
          .to receive(:call)
          .with(mandates, companies)
          .and_yield(inquiries, transfer_result[:errors])
          .and_return(transfer_result)

        subject.request_stock_transfer(mandates)
      end

      it "should update the inquiries after the transfer of mandates" do
        expect(inquiry1).to receive(:contact!).and_return(true)
        expect(inquiry2).to receive(:contact!).and_return(true)

        subject.request_stock_transfer(mandates)
      end

      it "should return the transfer result" do
        expect(subject.request_stock_transfer(mandates)).to eq(transfer_result)
      end

      it "should record errors, if an inquiry update fails" do
        allow(inquiry1).to receive(:contact!).and_raise(StandardError, "error1")
        allow(inquiry2).to receive(:contact!).and_raise(StandardError, "error2")

        result = subject.request_stock_transfer(mandates)

        expect(result[:errors]).not_to be_empty

        error1 = result[:errors][inquiry1]
        expect(error1).to be_a(StandardError)
        expect(error1.message).to eq("error1")

        error2 = result[:errors][inquiry2]
        expect(error2).to be_a(StandardError)
        expect(error2.message).to eq("error2")
      end
    end
  end
end
