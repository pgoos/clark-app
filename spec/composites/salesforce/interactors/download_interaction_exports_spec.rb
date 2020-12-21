# frozen_string_literal: true

require "rails_helper"
require "composites/salesforce/interactors/download_interaction_exports"

RSpec.describe Salesforce::Interactors::DownloadInteractionExports, :integration do
  subject { described_class.new }

  let(:host) { Settings.marketing_cloud.sftp_server_host }
  let(:username) { Settings.marketing_cloud.sftp_username }
  let(:port) { Settings.marketing_cloud.sftp_port }
  let(:key) { Settings.marketing_cloud.private_key }
  let(:passphrase) { Settings.marketing_cloud.private_key_passphrase }
  let(:remote_content) { "a,b,c" }
  let(:mocked_sftp_client) { double(download!: remote_content, dir: double(entries: [remote_file])) }
  let(:remote_filename) { "trackingextract2020_12_11.csv" }
  let(:remote_file) do
    Net::SFTP::Protocol::V01::Name.new(
      remote_filename, nil,
      Net::SFTP::Protocol::V01::Attributes.new(mtime: 1_607_709_600)
    )
  end

  before do
    allow(::Net::SFTP).to receive(:start).and_yield(mocked_sftp_client)
    Timecop.freeze("2020-12-12")
    MarketingCloudImport.create! created_at: 24.hours.ago
  end

  after do
    Timecop.return
  end

  describe "#sftp_download" do
    it "initializes Net::SFTP with right parameters" do
      expect(::Net::SFTP)
        .to receive(:start).with(host, username,
                                 port: port, key_data: [key], non_interactive: true,
                                 keys: [], keys_only: true)

      subject.call
    end

    it "initiates file upload using sftp client" do
      expect(mocked_sftp_client)
        .to receive(:download!).with(
          "#{described_class::DIRECTORY_TO_DOWNLOAD}/#{remote_filename}"
        ).and_return(remote_content)

      expect { subject.call }.to change(MarketingCloudImport, :count)
    end

    context "last import was done after last upload" do
      before do
        MarketingCloudImport.create! created_at: 5.minutes.ago
      end

      it "does not create new MarketingCloudImport" do
        expect { subject.call }.not_to change(MarketingCloudImport, :count)
      end
    end
  end
end
