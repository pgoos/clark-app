# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::DataProtection, :integration do
  subject { described_class }

  context "leads older than six weeks" do
    let(:oldest_times) { Time.now.utc - 11.weeks }
    let(:old_times) { Time.now.utc - 7.weeks }
    let(:old_inactive_mandate_with_inactive_lead_in_creation) do
      create(:mandate, state: "in_creation", created_at: old_times, updated_at: old_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: old_times, updated_at: old_times)
      end
    end
    let(:old_inactive_mandate_with_inactive_lead_freebie) do
      create(:mandate, state: "freebie", created_at: old_times, updated_at: old_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: old_times, updated_at: old_times)
      end
    end
    let(:old_inactive_mandate_with_inactive_lead_not_started) do
      create(:mandate, state: "not_started", created_at: old_times, updated_at: old_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: old_times, updated_at: old_times)
      end
    end
    let(:old_inactive_mandates_with_inactive_lead_in_creation_with_open_opportunity) do
      Opportunity
        .state_machine
        .states
        .keys
        .except(:completed)
        .each_with_object([]) do |state, result|
        result << create(:mandate, state: "in_creation", created_at: old_times, updated_at: old_times).tap do |mandate|
          create(:lead, mandate: mandate, created_at: old_times, updated_at: old_times)
          create(:opportunity, state: state, mandate: mandate)
        end
      end
    end

    let(:old_inactive_mandate_with_inactive_lead_in_creation_with_closed_opportunity) do
      create(:mandate, state: "in_creation", created_at: old_times, updated_at: old_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: old_times, updated_at: old_times)
        create(:opportunity, state: :completed, mandate: mandate)
      end
    end
    let(:old_inactive_mandate_with_inactive_lead_freebie_with_closed_opportunity) do
      create(:mandate, state: "freebie", created_at: old_times, updated_at: old_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: old_times, updated_at: old_times)
        create(:opportunity, state: :completed, mandate: mandate)
      end
    end
    let(:old_inactive_mandate_with_inactive_lead_not_started_with_closed_opportunity) do
      create(:mandate, state: "not_started", created_at: old_times, updated_at: old_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: old_times, updated_at: old_times)
        create(:opportunity, state: :completed, mandate: mandate)
      end
    end
    let(:old_inactive_mandate_with_inactive_lead_in_creation_with_closed_and_open_opportunity) do
      create(:mandate, state: "in_creation", created_at: old_times, updated_at: old_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: old_times, updated_at: old_times)
        create(:opportunity, state: :completed, mandate: mandate)
        create(:opportunity, state: :offer_phase, mandate: mandate)
      end
    end

    let(:old_inactive_mandate_with_active_lead) do
      create(:mandate, state: "in_creation", created_at: old_times, updated_at: old_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: old_times)
      end
    end
    let(:old_active_mandate_with_inactive_lead) do
      create(:mandate, state: "in_creation", created_at: old_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: old_times, updated_at: old_times)
      end
    end
    let(:old_inactive_mandate_with_user_not_created) do
      create(:mandate, state: "in_creation", created_at: old_times, updated_at: old_times).tap do |mandate|
        create(:user, mandate: mandate)
      end
    end
    let(:old_inactive_mandate_with_user_created) do
      create(:mandate, state: "created", created_at: old_times, updated_at: old_times).tap do |mandate|
        create(:user, mandate: mandate, created_at: old_times, updated_at: old_times)
      end
    end
    let(:oldest_inactive_mandate_with_user_created) do
      create(:mandate, state: "created", created_at: oldest_times, updated_at: oldest_times).tap do |mandate|
        create(:user, mandate: mandate, created_at: oldest_times, updated_at: oldest_times)
      end
    end
    let(:new_mandate_not_created) do
      create(:mandate, state: "in_creation").tap do |mandate|
        create(:lead, mandate: mandate)
      end
    end
    let(:new_mandate_created) do
      create(:mandate, state: "created").tap do |mandate|
        create(:lead, mandate: mandate)
      end
    end
    let(:new_mandate_with_user_created) do
      create(:mandate, state: "created").tap do |mandate|
        create(:user, mandate: mandate)
      end
    end

    before do
      old_inactive_mandate_with_inactive_lead_in_creation
      old_inactive_mandate_with_inactive_lead_freebie
      old_inactive_mandate_with_inactive_lead_not_started
      old_inactive_mandates_with_inactive_lead_in_creation_with_open_opportunity
      old_inactive_mandate_with_inactive_lead_in_creation_with_closed_opportunity
      old_inactive_mandate_with_inactive_lead_freebie_with_closed_opportunity
      old_inactive_mandate_with_inactive_lead_not_started_with_closed_opportunity
      old_inactive_mandate_with_inactive_lead_in_creation_with_closed_and_open_opportunity
      old_inactive_mandate_with_active_lead
      old_active_mandate_with_inactive_lead
      old_inactive_mandate_with_user_not_created
      old_inactive_mandate_with_user_created
      oldest_inactive_mandate_with_user_created
      new_mandate_not_created
      new_mandate_created
      new_mandate_with_user_created
    end

    it { expect(old_inactive_mandate_with_inactive_lead_in_creation.lead).to be }
    it do
      sql = subject.leads_older_than_six_weeks
      mandates = Mandate.find_by_sql(sql)
      expected_mandates = [
        old_inactive_mandate_with_inactive_lead_in_creation,
        old_inactive_mandate_with_inactive_lead_freebie,
        old_inactive_mandate_with_inactive_lead_not_started,
        *old_inactive_mandates_with_inactive_lead_in_creation_with_open_opportunity
      ]

      expect(
        mandates
      ).to contain_exactly(
        *expected_mandates
      )
    end

    context "when with documents as well" do
      let(:reminder_type) { DocumentType.find_by(key: "reminder2") || create(:document_type, key: "reminder2") }
      let(:oldest_times_with_reminders) { Time.now.utc - 7.weeks }
      let(:oldest_mandate_without_reminders_within_two_weeks) do
        create(
          :mandate,
          state: "in_creation",
          created_at: oldest_times_with_reminders,
          updated_at: oldest_times_with_reminders
        ).tap do |mandate|
          create(
            :lead,
            mandate: mandate,
            created_at: oldest_times_with_reminders,
            updated_at: oldest_times_with_reminders
          )
          create(
            :document,
            documentable: mandate,
            document_type: reminder_type,
            created_at: oldest_times_with_reminders
          )
        end
      end

      it "should work with the union statement" do
        expected_mandates = [
          old_inactive_mandate_with_inactive_lead_in_creation,
          old_inactive_mandate_with_inactive_lead_freebie,
          old_inactive_mandate_with_inactive_lead_not_started,
          oldest_mandate_without_reminders_within_two_weeks,
          *old_inactive_mandates_with_inactive_lead_in_creation_with_open_opportunity
        ]
        expected_mandates = expected_mandates.each_with_object([]) do |mandate, result|
          result << {"id" => mandate.id}
        end

        sql = subject.select_inactive_mandates
        mandates = ActiveRecord::Base.connection.execute(sql)

        expect(
          mandates
        ).to contain_exactly(
          *expected_mandates
        )
      end
    end
  end

  context "leads not responding on reminders for two weeks" do
    let(:now) { Time.now.utc }
    let(:oldest_times) { Time.now.utc - 7.weeks }
    let(:old_times) { Time.now.utc - 3.weeks }
    let(:newer_times) { Time.now.utc - 1.week }
    let(:reminder_type) { DocumentType.find_by(key: "reminder2") || create(:document_type, key: "reminder2") }
    let(:oldest_mandate_without_reminders_within_two_weeks) do
      create(:mandate, state: "in_creation", created_at: oldest_times, updated_at: oldest_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: oldest_times, updated_at: oldest_times)
        create(:document, documentable: mandate, document_type: reminder_type, created_at: old_times)
      end
    end
    let(:oldest_mandate_with_reminders_in_old_times_and_changes_in_old_times) do
      create(:mandate, state: "in_creation", created_at: oldest_times, updated_at: old_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: oldest_times, updated_at: old_times)
        create(:document, documentable: mandate, document_type: reminder_type, created_at: old_times)
      end
    end
    let(:old_mandate_without_reminders_within_two_weeks) do
      create(:mandate, state: "in_creation", created_at: old_times, updated_at: old_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: old_times, updated_at: old_times)
        create(:document, documentable: mandate, document_type: reminder_type, created_at: old_times)
      end
    end

    let(:oldest_mandates_without_reminders_within_two_weeks_with_open_opportunity) do
      Opportunity
        .state_machine
        .states
        .keys
        .except(:completed)
        .each_with_object([]) do |state, result|
        result << create(:mandate, state: "in_creation", created_at: oldest_times, updated_at: oldest_times).tap do |mandate|
          create(:lead, mandate: mandate, created_at: oldest_times, updated_at: oldest_times)
          create(:document, documentable: mandate, document_type: reminder_type, created_at: old_times)
          create(:opportunity, state: state, mandate: mandate)
        end
      end
    end

    let(:oldest_mandate_without_reminders_within_two_weeks_with_completed_opportunity) do
      create(:mandate, state: "in_creation", created_at: oldest_times, updated_at: oldest_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: oldest_times, updated_at: oldest_times)
        create(:document, documentable: mandate, document_type: reminder_type, created_at: old_times)
        create(:opportunity, state: :completed, mandate: mandate)
      end
    end
    let(:oldest_mandate_with_reminders_in_old_times_and_changes_in_old_times_with_completed_opportunity) do
      create(:mandate, state: "in_creation", created_at: oldest_times, updated_at: old_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: oldest_times, updated_at: old_times)
        create(:document, documentable: mandate, document_type: reminder_type, created_at: old_times)
        create(:opportunity, state: :completed, mandate: mandate)
      end
    end
    let(:old_mandate_without_reminders_within_two_weeks_with_completed_opportunity) do
      create(:mandate, state: "in_creation", created_at: old_times, updated_at: old_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: old_times, updated_at: old_times)
        create(:document, documentable: mandate, document_type: reminder_type, created_at: old_times)
        create(:opportunity, state: :completed, mandate: mandate)
      end
    end
    let(:oldest_mandate_without_reminders_within_two_weeks_with_completed_and_open_opportunity) do
      create(:mandate, state: "in_creation", created_at: oldest_times, updated_at: oldest_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: oldest_times, updated_at: oldest_times)
        create(:document, documentable: mandate, document_type: reminder_type, created_at: old_times)
        create(:opportunity, state: :completed, mandate: mandate)
        create(:opportunity, state: :offer_phase, mandate: mandate)
      end
    end

    let(:old_mandate_with_user_without_reminders_within_two_weeks) do
      create(:mandate, state: "in_creation", created_at: old_times, updated_at: old_times).tap do |mandate|
        create(:user, mandate: mandate, created_at: old_times, updated_at: old_times)
        create(:document, documentable: mandate, document_type: reminder_type, created_at: old_times)
      end
    end
    let(:old_mandate_with_reminders_within_two_weeks) do
      create(:mandate, state: "in_creation", created_at: old_times, updated_at: old_times).tap do |mandate|
        create(:lead, mandate: mandate, created_at: old_times, updated_at: old_times)
        create(:document, documentable: mandate, document_type: reminder_type, created_at: newer_times)
      end
    end

    before do
      oldest_mandate_without_reminders_within_two_weeks
      oldest_mandate_with_reminders_in_old_times_and_changes_in_old_times
      old_mandate_without_reminders_within_two_weeks
      oldest_mandates_without_reminders_within_two_weeks_with_open_opportunity
      oldest_mandate_without_reminders_within_two_weeks_with_completed_opportunity
      old_mandate_without_reminders_within_two_weeks_with_completed_opportunity
      oldest_mandate_with_reminders_in_old_times_and_changes_in_old_times_with_completed_opportunity
      oldest_mandate_without_reminders_within_two_weeks_with_completed_and_open_opportunity
      old_mandate_with_user_without_reminders_within_two_weeks
      old_mandate_with_reminders_within_two_weeks
    end

    it do
      expect(
        Mandate.find_by_sql(subject.leads_not_responding_on_reminders_for_two_weeks)
      ).to contain_exactly(
        oldest_mandate_without_reminders_within_two_weeks,
        old_mandate_without_reminders_within_two_weeks,
        oldest_mandate_with_reminders_in_old_times_and_changes_in_old_times,
        *oldest_mandates_without_reminders_within_two_weeks_with_open_opportunity
      )
    end
  end

  context "anonymize mandates" do
    let(:reminder_type) { DocumentType.find_by(key: "reminder2") || create(:document_type, key: "reminder2") }
    let(:sample_asset) { Rack::Test::UploadedFile.new(Core::Fixtures.fake_signature_file_path) }
    let!(:mandate1) do
      create(:mandate, state: "in_creation").tap do |mandate|
        create(:lead, mandate: mandate)
        create(
          :document,
          documentable: mandate,
          document_type: reminder_type,
          metadata: {to: "test@example.com"},
          asset: sample_asset
        )
        create(:ahoy_message, user: mandate, to: "banana2000@example.com").tap do |ahoy_message|
          create(:ahoy_message_delivery, ahoy_message: ahoy_message, email: "banana3000@example.com")
        end
        create(:phone, mandate: mandate)
      end
    end

    it do
      class FileSystemMock
        include Singleton

        def initialize
          @files = {}
        end

        def add(path, value)
          @files[path] = value
        end

        def delete(path)
          @files.delete(path)
        end

        def duplicate(original_path, to_path)
          @files[to_path] = @files[original_path]
        end

        def find(key)
          @files[key]
        end
      end

      module FileSystemUsage
        def file_system
          FileSystemMock.instance
        end

        def delete_multiple_objects(bucket_name, object_names, options={})
          object_names.each { |obj| file_system.delete(obj) }
          super
        end

        def put_object(bucket_name, object_name, data, options={})
          file_system.add(object_name, data.read)
          super
        end

        def copy_object(_source_directory, source_object_name, _target_directory, target_object_name, options={})
          file_system.duplicate(source_object_name, target_object_name)
          super
        end
      end

      class AssetMock
        def initialize(path)
          @path = path
          @value = file_system.find(@path)
        end

        def present?
          @value.present?
        end

        def file
          OpenStruct.new(read: @value)
        end

        def file=(value)
          file_system.add(@path, value)
        end

        def file_system
          FileSystemMock.instance
        end
      end

      class Fog::AWS::Storage::Mock
        prepend FileSystemUsage
      end

      Fog::AWS::Storage::Mock.instance_variable_set(
        :@data,
        Settings.fog.credentials.region => {
          Settings.fog.credentials.aws_access_key_id => {
            acls: {
              bucket: {},
              object: {}
            },
            buckets: {Settings.fog.private_directory => {objects: {}}},
            cors: {
              bucket: {}
            },
            bucket_notifications: {},
            bucket_tagging: {},
            multipart_uploads: {}
          }
        }
      )

      mandate1.documents.each do |document|
        value = document.asset.file.read

        def document.asset
          AssetMock.new("#{super.store_dir}/#{asset_before_type_cast}")
        end

        def document.asset=(value)
          asset.file = value
        end

        document.asset = value
      end

      DocumentUploader.storage = Fog::AWS::Storage::Mock
      DocumentUploader.fog_credentials[:provider] = Settings.fog.credentials.provider
      DocumentUploader.fog_credentials[:aws_access_key_id] = Settings.fog.credentials.aws_access_key_id
      DocumentUploader.fog_credentials[:aws_secret_access_key] = Settings.fog.credentials.aws_secret_access_key
      DocumentUploader.fog_directory = Settings.fog.private_directory

      subject.anonymize_mandates(mandate1.id)
      mandate1.reload
      expect(mandate1.first_name).to be_nil
      expect(mandate1.last_name).to be_nil
      expect(mandate1.street).to be_nil
      expect(mandate1.house_number).to be_nil
      expect(mandate1.zipcode).to be_nil
      expect(mandate1.city).to be_nil
      expect(mandate1.birthdate).to be_nil
      expect(mandate1.gender).to be_nil
      expect(mandate1.lead.email).to be_nil
      expect(mandate1.lead.subscriber).to be_falsy
      expect(mandate1.lead.registered_with_ip).to eq(IPAddr.new("0.0.0.0"))
      expect(mandate1.lead.source_data).not_to include(:advertiser_ids)
      DocumentUploader.storage = CarrierWave::Storage::File
      mandate1.documents.each do |document|
        def document.asset
          AssetMock.new("#{super.store_dir}/#{asset_before_type_cast}")
        end
        expect(document.metadata).to be_empty
        expect(document.asset.file.read).to include("This document was anonymized.")
      end
      mandate1.ahoy_messages.each do |ahoy_message|
        expect(ahoy_message.to).to be_nil
        Ahoy::MessageDelivery.where(ahoy_message: ahoy_message).each do |message_delivery|
          expect(message_delivery.email).to be_nil
        end
      end
      mandate1.phones.each do |phone|
        expect(phone.number).to eq("+491234567890")
      end
    end
  end

  context "asynchronous job logs" do
    let(:now) { Time.zone.now }
    let(:days_ago) { 30 }
    let(:threshold) { days_ago.days.ago.beginning_of_day }

    before do
      Timecop.freeze(now)
    end

    after do
      Timecop.return
    end

    it "should delete all entries of entries older than 30 days" do
      Timecop.travel(threshold - 1.day)
      create(:async_job_log)
      create(:async_job_log)

      Timecop.travel(threshold)
      to_keep = create(:async_job_log)

      Timecop.travel(now)
      described_class.delete_outdated_async_job_logs(days_ago: days_ago)
      expect(AsyncJobLog.all).to contain_exactly(to_keep)
    end
  end

  context "fonds finanz excels" do
    let(:excel_type) do
      excel_type = DocumentType.fonds_finanz_excel
      excel_type = create(:document_type, key: "fonds_finanz_excel") if excel_type.blank?
      excel_type
    end

    it "should delete all excels except 1" do
      create(:document, document_type: excel_type)
      last_doc = create(:document, document_type: excel_type)

      described_class.delete_outdated_fonds_finanz_excels(number_to_keep: 1)
      expect(Document.where(document_type: DocumentType.fonds_finanz_excel)).to contain_exactly(last_doc)
    end

    it "should delete all excels except 2" do
      create(:document, document_type: excel_type)
      last_docs = [
        create(:document, document_type: excel_type),
        create(:document, document_type: excel_type)
      ]

      described_class.delete_outdated_fonds_finanz_excels(number_to_keep: 2)
      expect(Document.where(document_type: DocumentType.fonds_finanz_excel)).to contain_exactly(*last_docs)
    end
  end
end
