# frozen_string_literal: true

require "rails_helper"

describe Qualitypool::PersonService do
  let(:ripcord_double) { instance_double(Ripcord::Client) }
  let(:subject) { Qualitypool::PersonService.new(ripcord_double) }
  let(:remote_new_person) { Qualitypool::PersonService::REMOTE_METHOD_NEW_PERSON }
  let(:remote_new_contact_details) { Qualitypool::PersonService::REMOTE_METHOD_NEW_CONTACT_DETAILS }
  let(:remote_new_document) { Qualitypool::PersonService::REMOTE_METHOD_NEW_DOCUMENT }

  context "invalid mandate" do
    let(:mandate) { instance_double(Mandate) }
    let(:validation_error_sentence) { "Validation error sentence." }

    before do
      allow(mandate).to receive(:is_a?).with(Mandate).and_return(true)
      allow(mandate).to receive(:qualitypool_id).and_return(nil)
      allow(mandate).to receive(:valid?).and_return(false)
      allow(mandate)
        .to receive_message_chain(:errors, :full_messages, :to_sentence)
        .and_return(validation_error_sentence)
    end

    it "raises an error at creation" do
      expect {
        subject.create_person(mandate)
      }.to raise_error(validation_error_sentence)
    end

    it "raises an error at document creation" do
      expect {
        subject.create_document(mandate)
      }.to raise_error(validation_error_sentence)
    end
  end

  context '#create_person' do
    let!(:mandate) { create(:mandate, user: create(:user)) }
    let(:success_response) { rpc_response(result: {Person: {:PersonID => 454920238}}) }

    it 'calls the API and stores the Qualitypool User Id in the Mandate' do
      expect(ripcord_double).to receive(:call).with(remote_new_person, Hash).and_return(success_response)
      subject.create_person(mandate)

      mandate.reload

      expect(mandate.qualitypool_id).to eq(454920238)
    end

    it 'can be called with a mandate_id and fetches the corresponding mandate' do
      expect(ripcord_double).to receive(:call).with(remote_new_person, Hash).and_return(success_response)
      subject.create_person(mandate)

      mandate.reload

      expect(mandate.qualitypool_id).to eq(454920238)
    end

    it 'does not update the model, if the request was not successful' do
      error_response = rpc_response(error: {:message => 'Invalid params', :code => -12345, :data => {'debug-message' => "the debug message: \n#/from remote"}})

      expect(ripcord_double).to receive(:call).with(remote_new_person, Hash).and_return(error_response)
      expect(mandate).not_to receive(:update_attributes!)
      expect(mandate).not_to receive(:update_attributes)

      subject.create_person(mandate)
    end

    it 'returns the response' do
      expect(ripcord_double).to receive(:call).with(remote_new_person, Hash).and_return(success_response)
      retval = subject.create_person(mandate)

      expect(retval).to be_kind_of(Ripcord::JsonRPC::Response)
    end
  end

  context '#create_document' do
    let!(:mandate) { create(:mandate, user: create(:user), qualitypool_id: 47110815) }
    let!(:document) { create(:document, documentable: mandate, document_type: DocumentType.mandate_document) }
    let(:success_response) { rpc_response(result: {:DokumentID => 456050212}) }

    it 'calls the API and does nothing when everything goes well' do
      expect(ripcord_double).to receive(:call).with(remote_new_document, Hash).and_return(success_response)
      subject.create_document(mandate)

      expect(mandate.current_mandate_document.qualitypool_id).to eq(456050212)
    end

    it 'raises an error when the mandate does not have a qualitypool_id' do
      mandate.update_attributes(qualitypool_id: nil)

      expect do
        subject.create_document(mandate)
      end.to raise_error(ArgumentError, /does not have a qualitypool_id set/)
    end

    it 'does not update the model, if the request was not successful' do
      error_response = rpc_response(error: {:message => 'Invalid params', :code => -12345, :data => {'debug-message' => "the debug message: \n#/from remote"}})

      expect(ripcord_double).to receive(:call).with(remote_new_document, Hash).and_return(error_response)
      expect(document).to_not receive(:update_attributes!)
      expect(document).to_not receive(:update_attributes)

      subject.create_document(mandate)
    end

    it 'returns the response' do
      expect(ripcord_double).to receive(:call).with(remote_new_document, Hash).and_return(success_response)
      retval = subject.create_document(mandate)

      expect(retval).to be_kind_of(Ripcord::JsonRPC::Response)
    end
  end

  it 'maps the basic mandate attributes to the TETHYS person' do
    mandate = Mandate.new(
      first_name: 'Clark',
      last_name: 'Kent',
      gender: 'male',
      phone: '+491711234567',
      birthdate: Date.new(1987, 5, 13),
      active_address_attributes: {
        street: 'Main Street',
        house_number: 13,
        zipcode: '62960',
        city: 'Metropolis',
        active: true,
        country_code: 'DE'
      },
    )
    mandate.user = User.new(mandate: mandate, email: 'clark.kent@daily-planet.com')

    person = subject.send(:person_from_mandate, mandate)

    expect(person[:PersonDaten][:Vorname]).to eq('Clark')
    expect(person[:PersonDaten][:Name]).to eq('Kent')
    expect(person[:PersonDaten][:Anrede]).to eq('1')
    expect(person[:PersonDaten][:Geschlecht]).to eq('1')
    expect(person[:PersonDaten][:Geburtsdatum]).to eq('1987-05-13')
    expect(person[:AnschriftDaten][:Strasse]).to eq('Main Street')
    expect(person[:AnschriftDaten][:Hausnummer]).to eq('13')
    expect(person[:AnschriftDaten][:Ort]).to eq('Metropolis')
    expect(person[:AnschriftDaten][:Postleitzahl]).to eq('62960')
    expect(person[:AnschriftDaten][:Land]).to eq('D')

    expect(person).not_to have_key(:Familienstand) # not supported by clark
    expect(person).not_to have_key(:Staatsangehoerigkeit) # not supported by clark
    expect(person).not_to have_key(:Berufstaetigkeit) # not supported by clark

    expect(
      JSON::Validator.validate(
        File.expand_path("../schema/Person.erstellen.schema.json", __FILE__),
        JSON.dump(person)
      )
    ).to be_truthy
  end

  it 'maps the mandate contact attributes to the TETHYS Kontaktdetails' do
    mandate = Mandate.new(
      qualitypool_id: 47110815,
      first_name: 'Clark',
      last_name: 'Kent',
      birthdate: Date.new(1987, 5, 13),
      gender: 'male',
      phone: '+491711234567',
      active_address_attributes: {
        street: 'Main Street',
        house_number: 13,
        zipcode: '62960',
        city: 'Metropolis',
        country_code: 'DE'
      }
    )
    mandate.user = User.new(mandate: mandate, email: 'clark.kent@daily-planet.com')
    mandate.save!

    contact_details_phone = subject.send(:contact_details_phone_from_mandate, mandate)
    contact_details_email = subject.send(:contact_details_email_from_mandate, mandate)

    expect(contact_details_phone[:PartnerID]).to eq(47110815)
    expect(contact_details_phone[:KommunikationsverbindungDaten][:Kommunikationsadresse]).to eq("+491711234567")
    expect(contact_details_phone[:KommunikationsverbindungDaten][:ArtID]).to eq("21")
    expect(contact_details_email[:PartnerID]).to eq(47110815)
    expect(contact_details_email[:KommunikationsverbindungDaten][:Kommunikationsadresse]).to eq("clark.kent@daily-planet.com")
    expect(contact_details_email[:KommunikationsverbindungDaten][:ArtID]).to eq("50")

    expect(
      JSON::Validator.validate(
        File.expand_path("../schema/Partner.erstelleKommunikationsverbindung.schema.json", __FILE__),
        JSON.dump(contact_details_phone)
      )
    ).to be_truthy
    expect(
      JSON::Validator.validate(
        File.expand_path("../schema/Partner.erstelleKommunikationsverbindung.schema.json", __FILE__),
        JSON.dump(contact_details_email)
      )
    ).to be_truthy
  end

  it 'maps the mandate attributes to the TETHYS document' do
    mandate = create(:mandate, qualitypool_id: 47110815)
    document = create(:document, documentable: mandate, document_type: DocumentType.mandate_document)

    tethys_document = subject.send(:document_from_mandate, mandate)

    expect(tethys_document[:PartnerID]).to eq(47110815)
    expect(tethys_document[:Dokument][:Dokumenteninformationen][:Sachgebiet]).to eq('Maklerauftrag')
    expect(tethys_document[:Dokument][:Dokumenteninformationen][:Bezeichnung]).to eq(document.asset.filename)
    expect(tethys_document[:Dokument][:Datei][:Dateiformat]).to eq('PDF')
    expect(tethys_document[:Dokument][:Datei][:Komprimierungstyp]).to eq('GZIP')
    expect(tethys_document[:Dokument][:Datei][:Pruefsumme][:Typ]).to eq('SHA1')
    expect(tethys_document[:Dokument][:Datei][:Pruefsumme][:Wert]).to eq(Digest::SHA1.hexdigest(document.asset.read))

    # Check that PDF is correctly encoded and zipped
    gzipped_base64_encoded_pdf = tethys_document[:Dokument][:Datei][:Daten]
    gzipped_pdf = Base64.strict_decode64(gzipped_base64_encoded_pdf)
    pdf = ActiveSupport::Gzip.decompress(gzipped_pdf)

    expect(pdf.force_encoding('BINARY')).to eq(document.asset.read.force_encoding('BINARY'))

    expect(
      JSON::Validator.validate(
        File.expand_path("../schema/Partner.erstelleDokument.schema.json", __FILE__),
        JSON.dump(tethys_document)
      )
    ).to be_truthy
  end

  def rpc_response(result: nil, error: nil)
    Ripcord::JsonRPC::Response.new(result, error, SecureRandom.hex(5))
  end
end
