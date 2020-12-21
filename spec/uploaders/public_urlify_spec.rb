require 'rails_helper'

describe PublicUrlify do

  it 'should modify an admin image uploader' do
    expect(Admin.new).to be_a_kind_of(PublicUrlify)
  end

  it 'should modify a logo image uploader' do
    expect(LogoUploader.new).to be_a_kind_of(PublicUrlify)
  end

  it 'should modify a category image uploader' do
    expect(CategoryImageUploader.new).to be_a_kind_of(PublicUrlify)
  end

  describe "#fog_public" do
    before do
      allow(Settings).to receive_message_chain("fog.allow_public_uploaders")
        .and_return(allow_public_uploaders)
    end

    let(:uploader_class) { Class.new { include(PublicUrlify) } }

    context "when fog.allow_public_uploaders = true" do
      let(:allow_public_uploaders) { true }

      it "returns true for fog_public" do
        expect(uploader_class.new.fog_public).to be(true)
      end
    end

    context "when fog.allow_public_uploaders = false" do
      let(:allow_public_uploaders) { false }

      it "returns true for fog_public" do
        expect(uploader_class.new.fog_public).to be(false)
      end
    end
  end
end
