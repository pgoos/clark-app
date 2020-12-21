require 'rails_helper'

RSpec.describe Qualitypool::VertragService do
  let(:ripcord_double) { instance_double(Ripcord::Client) }
  let(:subject) { Qualitypool::VertragService.new(ripcord_double) }
  let(:remote_new) { Qualitypool::VertragService::REMOTE_METHOD_NEW }
  let(:remote_start_transfer) { Qualitypool::VertragService::REMOTE_METHOD_START_TRANSFER }

  context "invalid product" do
    let(:product) { instance_double(Product) }
    let(:validation_error_sentence) { "Validation error sentence." }

    before do
      allow(product).to receive(:is_a?).with(Product).and_return(true)
      allow(product).to receive(:qualitypool_id).and_return(nil)
      allow(product).to receive(:valid?).and_return(false)
      allow(product)
        .to receive_message_chain(:errors, :full_messages, :to_sentence)
        .and_return(validation_error_sentence)
    end

    it "raises an error at creation" do
      expect {
        subject.create_product(product)
      }.to raise_error(validation_error_sentence)
    end

    it "raises an error at transfer" do
      expect {
        subject.start_transfer(product)
      }.to raise_error(validation_error_sentence)
    end
  end

  context '#create_product' do
    let!(:product) {
      create(:product,
             category: create(:category_phv),
             mandate: create(:mandate, qualitypool_id: 47110815)
      )
    }
    let(:success_response) {rpc_response(result: {:Vertrag => {:VertragID => 454920238}})}

    it 'calls the API and stores the Qualitypool Product Id in the Product' do
      expect(ripcord_double).to receive(:call).with(remote_new, Hash).and_return(success_response)
      subject.create_product(product)

      product.reload
      expect(product.qualitypool_id).to eq(454920238)
    end

    it 'throws an argument error, when the mandate does not have a qualitypool_id' do
      product.mandate.update_attributes(qualitypool_id: nil)

      expect do
        subject.create_product(product)
      end.to raise_error(ArgumentError)
    end

    it 'does not update the model, if the request was not successful' do
      error_response= rpc_response(error: {:message => 'Invalid params', :code => -12345, :data => {'debug-message' => "the debug message: \n#/from remote"}})

      expect(ripcord_double).to receive(:call).with(remote_new, Hash).and_return(error_response)
      expect(product).to_not receive(:update_attributes!)
      expect(product).to_not receive(:update_attributes)

      subject.create_product(product)
    end

    it 'returns the response' do
      expect(ripcord_double).to receive(:call).with(remote_new, Hash).and_return(success_response)
      retval = subject.create_product(product)

      expect(retval).to be_kind_of(Ripcord::JsonRPC::Response)
    end

    it "raises an exception, if the response is successful and the result is empty" do
      result_nil = rpc_response(result: {})
      allow(ripcord_double).to receive(:call).with(remote_new, Hash).and_return(result_nil)

      expect {
        subject.create_product(product)
      }.to raise_error(Qualitypool::Error, match(/The response structure is not as expected!.*/))
    end

    it "raises an exception, if the result does not contain 'Vertrag'" do
      result_nil = rpc_response(result: {wrong: "data"})
      allow(ripcord_double).to receive(:call).with(remote_new, Hash).and_return(result_nil)

      expect {
        subject.create_product(product)
      }.to raise_error(Qualitypool::Error, match(/The response structure is not as expected!.*/))
    end

    it "raises an exception, if the result does not contain 'Vertrag' -> 'VertragID'" do
      result_nil = rpc_response(result: {Vertrag: {}})
      allow(ripcord_double).to receive(:call).with(remote_new, Hash).and_return(result_nil)

      expect {
        subject.create_product(product)
      }.to raise_error(Qualitypool::Error, match(/The response structure is not as expected!.*/))
    end

    it "raises an exception, if the 'VertragID' is not an integer" do
      result_nil = rpc_response(result: {Vertrag: {VertragId: "not an integer"}})
      allow(ripcord_double).to receive(:call).with(remote_new, Hash).and_return(result_nil)

      expect {
        subject.create_product(product)
      }.to raise_error(Qualitypool::Error, match(/The response structure is not as expected!.*/))
    end

    it "raises an exception if the product does not have a sparte" do
      product.category.ident = "invalid"
      expect {
        subject.create_product(product)
      }.to raise_error(RuntimeError, "Could not map Category (#{product.category.ident}) to QualityPool Kennung")
    end
  end

  context '#start_transfer' do
    let!(:product) { create(:product, qualitypool_id: 12345678, managed_by_pool: nil, mandate: create(:mandate, qualitypool_id: 47110815)) }
    let(:success_response)      { rpc_response(result: { ProzessID: '977bbb19-4737-4b6f-b8cd-376e68112a36' }) }

    it 'calls the API and moves the product to takeover_requested, setting the correct pool' do
      expect(ripcord_double).to receive(:call).with(remote_start_transfer, Hash).and_return(success_response)
      subject.start_transfer(product)

      product.reload
      expect(product).to be_takeover_requested
      expect(product.managed_by_pool).to eq(Subcompany::POOL_QUALITY_POOL)
    end

    it 'throws an argument error, when the product does not have a qualitypool_id' do
      product.update_attributes(qualitypool_id: nil)

      expect {
        subject.start_transfer(product)
      }.to raise_error(ArgumentError, /does not have a qualitypool_id set/)
    end

    it 'returns the response' do
      expect(ripcord_double).to receive(:call).with(remote_start_transfer, Hash).and_return(success_response)
      retval = subject.start_transfer(product)

      expect(retval).to be_kind_of(Ripcord::JsonRPC::Response)
    end
  end

  context 'map product to tethys vertrag' do
    let!(:vertical) { create(:vertical, ident: 'SUHK') }
    let!(:mandate) { create(:mandate, qualitypool_id: 47110815) }
    let!(:category) { create(:phv_category_no_coverages, premium_type: 'gross') }
    let!(:subcompany) { create(:subcompany, pools: [Subcompany::POOL_QUALITY_POOL], bafin_id: 4711) }
    let!(:product) do
      create(:product,
        mandate: mandate,
        annual_maturity: { day: 1, month: 12 },
        premium_price: Money.new(69_99, 'EUR'),
        premium_state: 'premium',
        premium_period: 'year',
        number: 'VS-123456',
        plan: create(:plan, name: 'Super-PHV', subcompany: subcompany, category: category, vertical: vertical),
        contract_started_at: Time.zone.local(2016, 12, 1, 12, 0, 0),
        contract_ended_at: Time.zone.local(2017, 11, 30, 23, 59, 0)
      )
    end

    it 'maps the basic mandate attributes to the TETHYS person' do
      vertrag = subject.send(:vertrag_from_product, product)

      expect(vertrag[:PartnerID]).to eq(47110815)
      expect(vertrag[:VertragDaten]).not_to have_key(:Antragsdatum)
      expect(vertrag[:VertragDaten]).not_to have_key(:Abgangsdatum)
      expect(vertrag[:VertragDaten]).not_to have_key(:Abgangsgrund)
      expect(vertrag[:VertragDaten][:Hauptfaelligkeit]).to eq("12-01")
      expect(vertrag[:VertragDaten][:Vertragsstatus]).to eq("1")
      expect(vertrag[:VertragDaten][:Zahlungsweise]).to eq("1")
      expect(vertrag[:VertragDaten][:Vertragsnummer][:Versicherungsscheinnummer]).to eq("VS-123456")
      expect(vertrag[:VertragDaten][:Verkaufsprodukt][:Produkt][:Typ]).to eq("Privathaftpflichtversicherung")
      expect(vertrag[:VertragDaten][:Verkaufsprodukt][:Produkt][:Sparte]).to eq("040")
      expect(vertrag[:VertragDaten][:Verkaufsprodukt][:Produkt][:Unternehmen][:Nummernart]).to eq("BaFin")
      expect(vertrag[:VertragDaten][:Verkaufsprodukt][:Produkt][:Unternehmen][:Nummer]).to eq("4711")
      expect(vertrag[:VertragDaten][:Verkaufsprodukt]).not_to have_key(:Kennung)
      expect(vertrag[:VertragDaten][:Verkaufsprodukt][:Beitrag][:ArtID]).to eq("01")
      expect(vertrag[:VertragDaten][:Verkaufsprodukt][:Beitrag][:Betrag][:Betrag]).to eq(69.99)
      expect(vertrag[:VertragDaten][:Verkaufsprodukt][:Beitrag][:Betrag][:Waehrung]).to eq("EUR")
      expect(vertrag[:VertragDaten][:Verkaufsprodukt][:Produkt]).not_to have_key(:Kennung)
      expect(vertrag[:VertragDaten][:Verkaufsprodukt][:Versicherungsdauer][:Beginn]).to eq("2016-12-01T12:00")
      expect(vertrag[:VertragDaten][:Verkaufsprodukt][:Versicherungsdauer][:Ende]).to eq("2017-11-30T23:59")

      expect(
        JSON::Validator.validate(
          File.expand_path("../schema/Partner.erstelleVertrag.schema.json", __FILE__),
          JSON.dump(vertrag)
        )
      ).to be_truthy
    end

    it 'does not send _KEY_ or value for the contract_ended_at value, if it is null' do
      product.contract_ended_at = nil
      vertrag = subject.send(:vertrag_from_product, product)

      expect(vertrag[:VertragDaten][:Verkaufsprodukt][:Versicherungsdauer]).not_to have_key(:Ende)

      expect(
        JSON::Validator.fully_validate(
          File.expand_path("../schema/Partner.erstelleVertrag.schema.json", __FILE__),
          JSON.dump(vertrag)
        )
      ).to be_empty
    end
  end

  def rpc_response(result: nil, error: nil)
    Ripcord::JsonRPC::Response.new(result, error, SecureRandom.hex(5))
  end
end
