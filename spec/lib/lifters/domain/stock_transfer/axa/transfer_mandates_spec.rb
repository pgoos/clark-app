# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::StockTransfer::Axa::TransferMandates do
  let(:mandates) { [mandate1, mandate2, mandate3] }
  let(:mandate1) do
    n_instance_double(
      Mandate,
      "lea_musterfrau",
      inquiries: inquiries1,
      id: 42,
      gender: "female",
      first_name: "Lea",
      last_name: "Müsterfrau",
      zipcode: "12345",
      city: "Musterstadt",
      birthdate: Date.new(1980, 1, 1).to_time.in_time_zone,
      latest_mandate_document_with_biometric_data: doc1,
      confirmed_at: Date.new(2018, 6, 30).to_time.in_time_zone.noon
    )
  end
  let(:inquiries1) do
    [
      axa_inquiry1,
      wrong_axa_inquiry,
      n_instance_double(Inquiry, "wrong_inquiry1", company: wrong_company, pending?: true)
    ]
  end
  let(:axa_inquiry1) { n_instance_double(Inquiry, "axa_inquiry1", company: target_company1, pending?: true) }
  let(:wrong_axa_inquiry) { n_instance_double(Inquiry, "axa_inquiry1", company: target_company1, pending?: false) }
  let(:doc1) { n_instance_double(Document, "doc_lea") }

  let(:mandate2) do
    n_instance_double(
      Mandate,
      "max_mustermann",
      inquiries: inquiries2,
      id: 17,
      gender: "male",
      first_name: "Max",
      last_name: "Mustermann",
      zipcode: "12346",
      city: "Musterdorf",
      birthdate: Date.new(1991, 1, 2).to_time.in_time_zone,
      latest_mandate_document_with_biometric_data: doc2,
      confirmed_at: Date.new(2018, 7, 23).to_time.in_time_zone.noon
    )
  end
  let(:inquiries2) { [axa_inquiry2, n_instance_double(Inquiry, "inquiry2", company: wrong_company, pending?: true)] }
  let(:axa_inquiry2) { n_instance_double(Inquiry, "axa_inquiry2", company: target_company2, pending?: true) }
  let(:doc2) { n_instance_double(Document, "doc_max") }

  # Mandate with the same first and last name as mandate1 and without biometric mandate document:
  let(:mandate3) do
    n_instance_double(
      Mandate,
      "lea_musterfrau_same_name",
      inquiries: inquiries3,
      id: 23,
      gender: "female",
      first_name: "Lea",
      last_name: "Müsterfrau",
      zipcode: "12346",
      city: "Musterdorf",
      birthdate: Date.new(1981, 1, 2).to_time.in_time_zone,
      latest_mandate_document_with_biometric_data: nil,
      latest_mandate_document_without_biometric_data: doc3,
      confirmed_at: Date.new(2018, 1, 7).to_time.in_time_zone.noon
    )
  end
  let(:inquiries3) do
    [
      axa_inquiry3,
      n_instance_double(Inquiry, "wrong_inquiry3", company: wrong_company, pending?: true)
    ]
  end
  let(:axa_inquiry3) { n_instance_double(Inquiry, "axa_inquiry3", company: target_company1, pending?: true) }
  let(:doc3) { n_instance_double(Document, "doc_lea_same_name") }

  let(:companies) { [target_company1, target_company2] }
  let(:target_company1) { n_instance_double(Company, "target_company1") }
  let(:target_company2) { n_instance_double(Company, "target_company2") }
  let(:wrong_company) { n_instance_double(Company, "wrong_company") }

  let(:noon) { Time.zone.now.noon }
  let(:today) { noon.to_date }

  let(:mail) { n_double("mail") }
  let(:expected_mail_delivery) { :deliver_now }

  before do
    allow(InquiryMailer).to receive(:direct_transfer_request).with(any_args).and_return(mail)
    allow(mail).to receive(expected_mail_delivery)
    Timecop.freeze(noon)
  end

  after do
    Timecop.return
  end

  it "should have an inbound email address being set" do
    expect(subject.inbound_mail_address).to match(/\A\S+@\S+\z/)
  end

  it "should have an outbound email address being set" do
    expect(subject.outbound_mail_address).to match(/\A\S+@\S+\z/)
  end

  it "should know a valid csv encoding" do
    expect { "".encode(subject.csv_encoding) }.not_to raise_error
  end

  it "should set the inbound email address as 'from'" do
    expect(InquiryMailer).to receive(:direct_transfer_request).with(hash_including(from: subject.inbound_mail_address))
    subject.(mandates, companies) { |_, _| }
  end

  it "should set the outbound email address as 'to'" do
    expect(InquiryMailer).to receive(:direct_transfer_request).with(hash_including(to: subject.outbound_mail_address))
    subject.(mandates, companies) { |_, _| }
  end

  it "should set the inbound email address as 'cc'" do
    expect(InquiryMailer).to receive(:direct_transfer_request).with(hash_including(cc: subject.inbound_mail_address))
    subject.(mandates, companies) { |_, _| }
  end

  it "should set the subject" do
    expect(InquiryMailer).to receive(:direct_transfer_request).with(hash_including(subject: "STDBUE42"))
    subject.(mandates, companies) { |_, _| }
  end

  it "should set the csv file name with the date of today" do
    expected_file_name = "#{today.strftime('%y%m%d')}_inquiry.csv"
    expect(InquiryMailer).to receive(:direct_transfer_request).with(hash_including(csv_name: expected_file_name))
    subject.(mandates, companies) { |_, _| }
  end

  it "should provide the built csv" do
    expected_csv = <<~EOCSV
      Makler-FS;Anrede;Vorname;Nachname;Straße;PLZ;Ort;Telefon Vorwahl;Telefon Nummer;Geburtsdatum;HauptZielOrgaNr;Dateiname Mandat;Datum des Mandats;VSNR1;OrgaNr1;VSNR2;OrgaNr2;VSNR3;OrgaNr3;VSNR4;OrgaNr4;VSNR5;OrgaNr5;VSNR6;OrgaNr6;VSNR7;OrgaNr7;VSNR8;OrgaNr8;VSNR9;OrgaNr9;VSNR10;OrgaNr10
      42;Frau;Lea;Müsterfrau;;12345;Musterstadt;;;01.01.1980;6036007275;kunde-lea-müsterfrau.pdf;30.06.2018;;;;;;;;;;;;;;;;;;;;
      17;Herr;Max;Mustermann;;12346;Musterdorf;;;02.01.1991;6036007275;kunde-max-mustermann.pdf;23.07.2018;;;;;;;;;;;;;;;;;;;;
      23;Frau;Lea;Müsterfrau;;12346;Musterdorf;;;02.01.1981;6036007275;kunde-lea-müsterfrau1.pdf;07.01.2018;;;;;;;;;;;;;;;;;;;;
    EOCSV

    encoded_csv = expected_csv.encode(subject.csv_encoding)
    expect(InquiryMailer).to receive(:direct_transfer_request).with(hash_including(csv: encoded_csv))

    subject.(mandates, companies) { |_, _| }
  end

  it "should provide the document mapping" do
    expected_mandate_docs = {
      "kunde-lea-müsterfrau.pdf".encode(subject.csv_encoding) => doc1,
      "kunde-max-mustermann.pdf".encode(subject.csv_encoding) => doc2,
      "kunde-lea-müsterfrau1.pdf".encode(subject.csv_encoding) => doc3
    }
    expect(InquiryMailer).to receive(:direct_transfer_request).with(hash_including(mandate_docs: expected_mandate_docs))
    subject.(mandates, companies) { |_, _| }
  end

  it "should send the mail" do
    expect(mail).to receive(expected_mail_delivery)
    subject.(mandates, companies) { |_, _| }
  end

  it "should yield the inquiries and the errors container" do
    expect { |block| subject.(mandates, companies, &block) }
      .to yield_with_args([axa_inquiry1, axa_inquiry2, axa_inquiry3], {})
  end

  it "should add the transferred mandates to the result" do
    result = subject.(mandates, companies) { |_, _| }
    expect(result[:transferred_entities]).to eq(mandates)
  end

  context "when already processed" do
    before do
      [axa_inquiry1, axa_inquiry2, axa_inquiry3].each { |i| allow(i).to receive(:pending?).and_return(false) }
    end

    it "should not send the mail" do
      expect(mail).not_to receive(expected_mail_delivery)
      subject.(mandates, companies) { |_, _| }
    end

    it "should not hand over the control to the caller" do
      expect { |block| subject.(mandates, companies, &block) }.not_to yield_control
    end

    it "should return an empty result" do
      result = subject.(mandates, companies) { |_, _| }
      expect(result).to eq(transferred_entities: [], errors: {})
    end
  end

  context "when the transfer fails" do
    {
      CSV => :generate,
      InquiryMailer => :direct_transfer_request
    }.each do |object, method|
      context "when the call of #{method} on the object #{object} fails" do
        let(:err_message) { "sample error (#{rand})" }

        before { allow(object).to receive(method).with(any_args).and_raise(err_message) }

        it "should not send the mail" do
          expect(mail).not_to receive(expected_mail_delivery)
        end

        it "should not hand over the control to the caller" do
          expect { |block| subject.(mandates, companies, &block) }.not_to yield_control
        end

        it "should not show transferred entities in the result" do
          result = subject.(mandates, companies) { |_, _| }
          expect(result[:transferred_entities]).to be_empty
        end

        it "should return the result hash with an error message" do
          result = subject.(mandates, companies) { |_, _| }
          transfer_failed = result[:errors][:fatal]
          expect(transfer_failed).to be_a(StandardError)
          expect(transfer_failed.message).to eq(err_message)
        end
      end
    end

    it "should report the mandate specific failure, if available" do
      err_message = "sample error #{rand}"
      allow(mandate3).to receive(:latest_mandate_document_without_biometric_data).and_raise(err_message)
      result = subject.(mandates, companies) { |_, _| }
      transfer_failed = result[:errors][mandate3]
      expect(transfer_failed).to be_a(StandardError)
      expect(transfer_failed.message).to eq(err_message)
    end
  end
end
