# frozen_string_literal: true

require "rails_helper"

describe Qualitypool::StockTransferService do
  let(:person_service_double) { instance_double(Qualitypool::PersonService) }
  let(:vertrag_service_double) { instance_double(Qualitypool::VertragService) }

  let(:success_response) { Ripcord::JsonRPC::Response.new({ success: true }, nil, SecureRandom.hex(5)) }
  let(:err_mess_key) { Qualitypool::BasicRPCService::ERROR_MESSAGE_KEY }
  let(:failure_response) { Ripcord::JsonRPC::Response.new(nil, { data: { err_mess_key => "something went wrong" } }, SecureRandom.hex(5)) }

  let(:subject) { Qualitypool::StockTransferService.new }

  let!(:mandate) { create(:mandate, :with_phone) }
  let!(:product) { create(:product, mandate: mandate) }
  let!(:document) { create(:document, document_type: DocumentType.mandate_document, documentable: mandate) }

  before do
    allow(subject).to receive(:person_service).and_return(person_service_double)
    allow(subject).to receive(:vertrag_service).and_return(vertrag_service_double)
  end

  context "#create_mandate_if_needed" do
    it "creates person if mandate does not have a qualitypool_id" do
      allow(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)

      subject.send(:create_mandate_if_needed, product)
      expect(subject.actions[product]).to match_array([:person])
    end

    it "does not create a person when the mandate has a qualitypool_id" do
      mandate.update_attributes(qualitypool_id: 47110815)

      expect(person_service_double).not_to receive(:create_person)

      subject.send(:create_mandate_if_needed, product)
      expect(subject.actions[product]).to be_empty
    end

    it "returns response object when everything went well" do
      allow(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)

      response = subject.send(:create_mandate_if_needed, product)

      expect(response).to be_kind_of(Ripcord::JsonRPC::Response)
    end

    it "has an error when user has a IBAN" do
      mandate.update(iban: "DE09500105178416334625")

      allow(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)
      allow(person_service_double).to receive(:create_contact_details_phone).with(mandate).and_return(success_response)

      subject.send(:create_mandate_if_needed, product)
      product.mandate.valid?

      response = subject.send(:create_contact_details_phone, product)
      expect(response).to be_kind_of(Ripcord::JsonRPC::Response)
    end
  end

  context "#create_mandate_document_if_needed" do
    it "creates document if mandate document does not have a qualitypool_id" do
      allow(person_service_double).to receive(:create_document).with(mandate).and_return(success_response)

      subject.send(:create_mandate_document_if_needed, product)
      expect(subject.actions[product]).to match_array([:mandate_document])
    end

    it "does not create a document when the mandate document has a qualitypool_id" do
      document.update_attributes(qualitypool_id: 47110815)

      expect(person_service_double).not_to receive(:create_document)

      subject.send(:create_mandate_document_if_needed, product)
      expect(subject.actions[product]).to be_empty
    end

    it "returns response object when everything went well" do
      allow(person_service_double).to receive(:create_document).with(mandate).and_return(success_response)

      response = subject.send(:create_mandate_document_if_needed, product)

      expect(response).to be_kind_of(Ripcord::JsonRPC::Response)
    end
  end

  context "#create_product_if_needed" do
    it "creates product" do
      allow(vertrag_service_double).to receive(:create_product).with(product).and_return(success_response)
      subject.send(:create_product_if_needed, product)
      expect(subject.actions[product]).to match_array([:product])
    end

    it "does not create product if the product has a qualitypool_id" do
      product.update_attributes(qualitypool_id: 47110815)

      expect(vertrag_service_double).not_to receive(:create_product)

      subject.send(:create_product_if_needed, product)
      expect(subject.actions[product]).to be_empty
    end
  end

  context "#start_transfer" do
    it "starts transfer for product" do
      expect(vertrag_service_double).to receive(:start_transfer).with(product).and_return(success_response)
      subject.send(:start_transfer, product)
      expect(subject.actions[product]).to match_array([:transfer])
    end
  end

  context "#transfer" do
    context "exception handling" do
      let(:error) { I18n.t("admin.qualitypool.remote_error_wrapper", message: "ArgumentError: some error") }

      it "should provide an I18n value" do
        expect(error).not_to match(/translation/)
      end

      it "catches RPC exceptions in create_person" do
        expect(person_service_double).to receive(:create_person).and_raise(ArgumentError.new("some error"))
        expect {
          subject.transfer(product)
        }.to raise_error(Qualitypool::StockTransferError)

        expect(subject.actions[product]).to be_empty
        expect(subject.errors[product]).to match_array([error])
      end

      it "catches RPC exceptions in create_document" do
        expect(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_phone).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_email).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_document).and_raise(ArgumentError.new("some error"))
        expect(vertrag_service_double).not_to receive(:create_product)
        expect(vertrag_service_double).not_to receive(:start_transfer)
        expect {
          subject.transfer(product)
        }.to raise_error(Qualitypool::StockTransferError)

        expect(subject.actions[product]).to match_array([:person, :contact_details_email, :contact_details_phone])
        expect(subject.errors[product]).to match_array([error])
      end

      it "catches RPC exceptions in create_product" do
        expect(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_phone).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_email).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_document).with(mandate).and_return(success_response)
        expect(vertrag_service_double).to receive(:create_product).and_raise(ArgumentError.new("some error"))
        expect(vertrag_service_double).not_to receive(:start_transfer)

        expect {
          subject.transfer(product)
        }.to raise_error(Qualitypool::StockTransferError)

        expect(subject.actions[product]).to match_array([:person, :mandate_document, :contact_details_email, :contact_details_phone])
        expect(subject.errors[product]).to match_array([error])
      end

      it "catches RPC exceptions in start_transfer" do
        expect(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_phone).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_email).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_document).with(mandate).and_return(success_response)
        expect(vertrag_service_double).to receive(:create_product).with(product).and_return(success_response)
        expect(vertrag_service_double).to receive(:start_transfer).with(product).and_raise(ArgumentError.new("some error"))

        expect {
          subject.transfer(product)
        }.to raise_error(Qualitypool::StockTransferError)

        expect(subject.actions[product]).to match_array([:person, :mandate_document, :product, :contact_details_email, :contact_details_phone])
        expect(subject.errors[product]).to match_array([error])
      end
    end

    context "error response handling" do
      let(:error) { I18n.t("admin.qualitypool.remote_error_wrapper", message: "something went wrong") }

      it "handles a RPC response with an error in create_person" do
        expect(person_service_double).to receive(:create_person).with(mandate).and_return(failure_response)
        expect(person_service_double).not_to receive(:create_contact_details_phone)
        expect(person_service_double).not_to receive(:create_contact_details_email)
        expect(person_service_double).not_to receive(:create_document)
        expect(vertrag_service_double).not_to receive(:create_product)
        expect(vertrag_service_double).not_to receive(:start_transfer)

        expect {
          subject.transfer(product)
        }.to raise_error(Qualitypool::StockTransferError)

        expect(subject.actions[product]).to be_empty
        expect(subject.errors[product]).to match_array([error])
      end

      it "handles a RPC response with an error in create_contact_details_email" do
        expect(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_email).with(mandate).and_return(failure_response)
        expect(person_service_double).not_to receive(:create_contact_details_phone)
        expect(person_service_double).not_to receive(:create_document)
        expect(vertrag_service_double).not_to receive(:create_product)
        expect(vertrag_service_double).not_to receive(:start_transfer)

        expect {
          subject.transfer(product)
        }.to raise_error(Qualitypool::StockTransferError)

        expect(subject.actions[product]).to match_array([:person])
        expect(subject.errors[product]).to match_array([error])
      end

      it "handles a RPC response with an error in create_contact_details_phone" do
        expect(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_email).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_phone).with(mandate).and_return(failure_response)
        expect(person_service_double).not_to receive(:create_document)
        expect(vertrag_service_double).not_to receive(:create_product)
        expect(vertrag_service_double).not_to receive(:start_transfer)

        expect {
          subject.transfer(product)
        }.to raise_error(Qualitypool::StockTransferError)


        expect(subject.actions[product]).to match_array(%i[person contact_details_email])
        expect(subject.errors[product]).to match_array([error])
      end

      it "handles a RPC response with an error in create_document" do
        expect(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_phone).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_email).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_document).with(mandate).and_return(failure_response)
        expect(vertrag_service_double).not_to receive(:create_product)
        expect(vertrag_service_double).not_to receive(:start_transfer)

        expect {
          subject.transfer(product)
        }.to raise_error(Qualitypool::StockTransferError)

        expect(subject.actions[product]).to match_array(%i[person contact_details_email contact_details_phone])
        expect(subject.errors[product]).to match_array([error])
      end

      it "handles a RPC response with an error in create_product" do
        expect(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_phone).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_email).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_document).with(mandate).and_return(success_response)
        expect(vertrag_service_double).to receive(:create_product).with(product).and_return(failure_response)
        expect(vertrag_service_double).not_to receive(:start_transfer)

        expect {
          subject.transfer(product)
        }.to raise_error(Qualitypool::StockTransferError)

        expect(subject.actions[product]).to match_array(%i[person contact_details_email contact_details_phone mandate_document])
        expect(subject.errors[product]).to match_array([error])
      end

      it "handles a RPC response with an error in start_transfer" do
        expect(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_phone).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_contact_details_email).with(mandate).and_return(success_response)
        expect(person_service_double).to receive(:create_document).with(mandate).and_return(success_response)
        expect(vertrag_service_double).to receive(:create_product).with(product).and_return(success_response)
        expect(vertrag_service_double).to receive(:start_transfer).with(product).and_return(failure_response)

        expect {
          subject.transfer(product)
        }.to raise_error(Qualitypool::StockTransferError)

        expect(subject.actions[product]).to match_array(%i[person contact_details_email contact_details_phone mandate_document product])
        expect(subject.errors[product]).to match_array([error])
      end
    end

    it "returns true and marks all actions when everything went correctly" do
      expect(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)
      expect(person_service_double).to receive(:create_contact_details_phone).with(mandate).and_return(success_response)
      expect(person_service_double).to receive(:create_contact_details_email).with(mandate).and_return(success_response)
      expect(person_service_double).to receive(:create_document).with(mandate).and_return(success_response)
      expect(vertrag_service_double).to receive(:create_product).with(product).and_return(success_response)
      expect(vertrag_service_double).to receive(:start_transfer).with(product).and_return(success_response)

      subject.transfer(product)

      expect(subject.actions[product]).to match_array(%i[person contact_details_phone contact_details_email mandate_document product transfer])
      expect(subject.skipped_actions[product]).to be_empty
      expect(subject.errors[product]).to be_empty
    end

    it "skips the person and contact actions when person is already present" do
      mandate.update(qualitypool_id: 47110815)

      expect(person_service_double).not_to receive(:create_person).with(mandate)
      expect(person_service_double).not_to receive(:create_contact_details_phone).with(mandate)
      expect(person_service_double).not_to receive(:create_contact_details_email).with(mandate)
      expect(person_service_double).to receive(:create_document).with(mandate).and_return(success_response)
      expect(vertrag_service_double).to receive(:create_product).with(product).and_return(success_response)
      expect(vertrag_service_double).to receive(:start_transfer).with(product).and_return(success_response)

      subject.transfer(product)

      expect(subject.actions[product]).to match_array(%i[mandate_document product transfer])
      expect(subject.skipped_actions[product]).to match_array([:person])
      expect(subject.errors[product]).to be_empty
    end

    it "skips the mandate document action when it's already present" do
      mandate.update(qualitypool_id: 47110815)
      document.update(qualitypool_id: 87654321)

      expect(person_service_double).not_to receive(:create_person)
      expect(person_service_double).not_to receive(:create_contact_details_phone)
      expect(person_service_double).not_to receive(:create_contact_details_email)
      expect(person_service_double).not_to receive(:create_document)
      expect(vertrag_service_double).to receive(:create_product).with(product).and_return(success_response)
      expect(vertrag_service_double).to receive(:start_transfer).with(product).and_return(success_response)

      subject.transfer(product)

      expect(subject.actions[product]).to match_array(%i[product transfer])
      expect(subject.skipped_actions[product]).to match_array(%i[person mandate_document])
      expect(subject.errors[product]).to be_empty
    end

    it "skips the person, document and product actions when it's already present" do
      mandate.update(qualitypool_id: 47110815)
      document.update(qualitypool_id: 87654321)
      product.update(qualitypool_id: 12345678)

      expect(person_service_double).not_to receive(:create_person)
      expect(person_service_double).not_to receive(:create_contact_details_phone)
      expect(person_service_double).not_to receive(:create_contact_details_email)
      expect(person_service_double).not_to receive(:create_document)
      expect(vertrag_service_double).not_to receive(:create_product)
      expect(vertrag_service_double).to receive(:start_transfer).with(product).and_return(success_response)

      subject.transfer(product)

      expect(subject.actions[product]).to match_array([:transfer])
      expect(subject.skipped_actions[product]).to match_array(%i[person mandate_document product])
      expect(subject.errors[product]).to be_empty
    end

    describe "creation of phone details" do
      let(:skipped_actions) { subject.skipped_actions[product] }

      before do
        allow(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)
        allow(person_service_double).to receive(:create_contact_details_phone).with(mandate).and_return(success_response)
        allow(person_service_double).to receive(:create_contact_details_email).with(mandate).and_return(success_response)
        allow(person_service_double).to receive(:create_document).with(mandate).and_return(success_response)
        allow(vertrag_service_double).to receive(:create_product).with(product).and_return(success_response)
        allow(vertrag_service_double).to receive(:start_transfer).with(product).and_return(success_response)
      end

      context "when mandate has a phone" do
        before { subject.transfer(product) }

        it "creates phone details" do
          expect(skipped_actions).to be_empty
        end
      end

      context "when mandate has no phone" do
        let(:mandate) { create(:mandate) }

        it "does not create phone details" do
          subject.transfer(product)
          expect(skipped_actions).to match_array([:contact_details_phone])
        end

        it "does not call #create_contact_details_phone" do
          expect(person_service_double).not_to receive(:create_contact_details_phone)

          subject.transfer(product)
        end
      end
    end
  end

  describe "concurrency issues", truncation: true do
    let(:product1) { product.reload }
    let(:product2) { product.reload }
    let(:qualitypool_id) { 30 }

    def spawn_threads!
      threads = [product1, product2].map do |p|
        Thread.new do
          subject.transfer(p)
        end
      end
      threads.map(&:join)
    end

    before do
      allow(vertrag_service_double).to receive(:start_transfer).and_return(success_response)
    end

    context "with mandate" do
      before do
        allow(person_service_double).to receive(:create_contact_details_phone).and_return(success_response)
        allow(person_service_double).to receive(:create_contact_details_email).and_return(success_response)
      end

      it "does not call the API multiple times to create a new mandate" do
        document.update(qualitypool_id: 10)
        product.update(qualitypool_id: 20)

        allow(person_service_double).to receive(:create_person) do |mandate|
          mandate.update!(qualitypool_id: qualitypool_id)
          success_response
        end

        spawn_threads!

        expect(person_service_double).to have_received(:create_person).once
        expect(person_service_double).to \
          have_received(:create_contact_details_phone).once
        expect(person_service_double).to \
          have_received(:create_contact_details_email).once
        expect(mandate.reload.qualitypool_id).to be_present
      end
    end

    context "with document" do
      it "does not creates the document twice" do
        mandate.update(qualitypool_id: 30)
        product.update(qualitypool_id: 20)

        allow(person_service_double).to receive(:create_document) do |mandate|
          mandate.current_mandate_document.update!(qualitypool_id: qualitypool_id)
          success_response
        end

        spawn_threads!

        expect(person_service_double).to have_received(:create_document).once
        expect(document.reload.qualitypool_id).to be_present
      end
    end

    context "with product" do
      # https://clarkteam.atlassian.net/browse/JCLARK-43677
      skip("We need to find a way to coordinate the two threads and have a more reliable spec")

      it "does not creates the product twice" do
        mandate.update(qualitypool_id: 30)
        document.update(qualitypool_id: 20)

        allow(vertrag_service_double).to receive(:create_product) do |product|
          # If we remove the sleep here, then the first thread finishes early than the second one
          # and then we don't test the correct behavior
          sleep 0.01
          product.update!(qualitypool_id: qualitypool_id)
          success_response
        end

        spawn_threads!

        expect(vertrag_service_double).to have_received(:create_product).once
        expect(product.reload.qualitypool_id).to be_present
      end
    end

    context "with product transfer" do
      skip("We need to find a way to coordinate the two threads and have a more reliable spec")

      let(:mock_service_method) do
        lambda do |product|
          sleep 0.01
          product.request_takeover!
          success_response
        end
      end

      it "does not transfer the product twice" do
        mandate.update(qualitypool_id: 30)
        document.update(qualitypool_id: 20)
        product.update(qualitypool_id: 40)

        allow(vertrag_service_double).to receive(:start_transfer, &mock_service_method)

        spawn_threads!

        expect(vertrag_service_double).to have_received(:start_transfer).once
        expect(product.reload.state).to eq "takeover_requested"
      end
    end

    describe "create_mandate_if_needed" do
      context "changed mandate" do
        before do
          mandate = product1.mandate
          mandate.assign_attributes(state: "created")
        end

        it "does not raise RuntimeError" do
          allow(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)

          expect { subject.send(:create_mandate_if_needed, product1) }.not_to raise_error(RuntimeError)
        end

        it "does not triggered Sentry notification" do
          allow(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)

          expect(Raven).not_to receive(:capture_message)
          expect(person_service_double).to receive(:create_person)

          subject.send(:create_mandate_if_needed, product1)
        end
      end

      context "changed mandate (invalid state)" do
        before do
          mandate = product1.mandate
          mandate.assign_attributes(state: "invalid_state")
        end

        it "raise RuntimeError" do
          allow(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)

          expect { subject.send(:create_mandate_if_needed, product1) }.to raise_error(RuntimeError)
        end

        it "triggered Sentry notification" do
          allow(person_service_double).to receive(:create_person).with(mandate).and_return(success_response)
          allow_any_instance_of(Mandate).to receive(:with_lock).and_return(true)

          expect(Raven).to receive(:capture_message)

          subject.send(:create_mandate_if_needed, product1)
        end
      end
    end
  end
end
