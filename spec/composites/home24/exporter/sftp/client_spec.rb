# frozen_string_literal: true

require "rails_helper"
require "composites/home24/exporter/sftp/client"

RSpec.describe Home24::Exporter::Sftp::Client do
  subject { described_class.new }

  let(:host) { Settings.neodigital.sftp_server_host }
  let(:username) { Settings.neodigital.sftp_username }
  let(:port) { Settings.neodigital.sftp_port }
  let(:key) { Settings.neodigital.private_key }
  let(:passphrase) { Settings.neodigital.private_key_passphrase }
  let(:mocked_sftp_client) { double(upload!: true) }
  let(:file_path_tu_upload) { "test.zip" }
  let(:remote_filename) { "test.zip" }

  before do
    allow(::Net::SFTP).to receive(:start).and_yield(mocked_sftp_client)
  end

  describe "#upload" do
    it "initializes Net::SFTP with right parameters" do
      expect(::Net::SFTP)
        .to receive(:start).with(host, username,
                                 port: port, key_data: [key], non_interactive: true,
                                 passphrase: passphrase, keys: [], keys_only: true)

      subject.upload(file_path_tu_upload, remote_filename)
    end

    it "initiates file upload using sftp client" do
      expect(mocked_sftp_client)
        .to receive(:upload!).with(file_path_tu_upload, described_class::DIRECTORY_TO_UPLOAD + "/" + remote_filename)

      subject.upload(file_path_tu_upload, remote_filename)
    end
  end
end
