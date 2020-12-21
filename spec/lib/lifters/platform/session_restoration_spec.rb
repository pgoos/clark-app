require 'rails_helper'

RSpec.describe Platform::LeadSessionRestoration do
  let(:lead) { create(:lead) }
  let(:url) { "/app/mandate/confirming" }
  let(:random_token) { "randomlyGeneratedToken" }
  let(:encrypted_token) { "encryptedToken" }

  before do
    allow(SecureRandom).to receive(:uuid).and_return(random_token)
    allow(Platform::LeadSessionRestoration).to receive(:encrypt_restoration_token).and_return(encrypted_token)
    allow(Platform::LeadSessionRestoration).to receive(:decrypt_restoration_token).and_return(random_token)
  end

  context "when #add_session_restoration_token" do
    it "adds the session restoration token to the lead" do
      described_class.add_session_restoration_token(lead)
      expect(lead.restore_session_token).to eq(random_token)
    end

    context "when the session id is already present it returns it" do
      let(:existing_token) { "existingToken" }

      before do
        lead.restore_session_token = existing_token
        lead.save!
      end

      it "updates the restoration token to the new one" do
        expect(lead.restore_session_token).to eq(existing_token)
        described_class.add_session_restoration_token(lead)
        expect(lead.restore_session_token).to eq(existing_token)
      end
    end
  end

  context "when #create_url_with_encrypted_data" do
    it "creates a url with the encrypted token" do
      appended_url = described_class.create_url_with_encrypted_data(random_token, url)
      expect(appended_url).to eq("#{url}?restoration_token=#{encrypted_token}")
    end

    it "does not create a url if token is nil" do
      appended_url = described_class.create_url_with_encrypted_data(nil, url)
      expect(appended_url).to be_nil
    end

    it "does not create a url if url is empty" do
      appended_url = described_class.create_url_with_encrypted_data(random_token, "")
      expect(appended_url).to be_nil
    end
  end

  context "when #fetch_session_restoration_token_from_url" do
    let(:url_with_encrypted_token) { "#{url}?#{:restoration_token}=#{encrypted_token}" }

    it "extracts the session token from the url" do
      extracted_token = described_class.fetch_session_restoration_token_from_url(url_with_encrypted_token)
      expect(extracted_token).to eq(random_token)
    end

    it "returns empty if url is empty" do
      extracted_token = described_class.fetch_session_restoration_token_from_url("")
      expect(extracted_token).to be_nil
    end

    it "returns empty if url does not have the query param" do
      extracted_token = described_class.fetch_session_restoration_token_from_url(url)
      expect(extracted_token).to be_nil
    end
  end

  context "when #find_lead_from_token" do
    let(:lead_with_token) { create(:lead, restore_session_token: random_token) }

    before do
      lead_with_token
    end

    it "returns lead with the given token" do
      result = described_class.find_lead_from_token(random_token)
      expect(result).to eq(lead_with_token)
    end

    it "returns nil if no lead with token exists" do
      result = described_class.find_lead_from_token("someRandomValue")
      expect(result).to be_nil
    end

    it "returns nil if token is nil" do
      result = described_class.find_lead_from_token(nil)
      expect(result).to be_nil
    end
  end

  context "when #decrypt_and_return_lead" do
    let(:lead_with_token) { create(:lead, restore_session_token: random_token) }

    before do
      lead_with_token
    end

    it "returns the lead with decrypted token" do
      result = described_class.decrypt_and_return_lead(encrypted_token)
      expect(result).to eq(lead_with_token)
    end
  end
end
