require 'rails_helper'

RSpec.describe 'Admin resets a revoked mandate', :slow, :browser, type: :feature do

  let(:locale) { I18n.locale }
  def mock_cms
    allow(Comfy::Cms::File).to receive(:find_by_label).and_return(double(file: double(url: 'dummy.url')))
  end

  let(:user) do
    user = create(:user)
    user.confirm
    user
  end

  before do
    login_as(user, scope: :user)
    mock_cms
  end

  before :each do
    login_super_admin
    mandate = create(:mandate, state: 'rejected', tos_accepted_at: Time.now, confirmed_at: Time.now)
    user.update_attributes(mandate: mandate)
    mandate.reload
    mandate.signatures << create(:signature)
    allow_any_instance_of(Mandate).to receive(:signature_png_base64).and_return("data:image/png;base64,XXXXXXXXXXX")
    mandate.documents << create(:document, document_type: DocumentType.mandate_document)
    mandate.info['wizard_steps'] = ['targeting', 'profiling', 'confirming']
    mandate.save!
  end

  it 'resets the wizard to profiling', skip: "excluded from nightly, review" do
    visit admin_mandate_path(locale: I18n.locale, id: user.mandate.id)
    expect {
      click_link I18n.t('activerecord.state_machines.events.reset')
      user.mandate.reload
    }.to change{user.mandate.wizard_steps}.from(['targeting', 'profiling', 'confirming']).to(['targeting', 'profiling'])
  end

  it 'deletes the mandate documents', skip: "excluded from nightly, review" do
    visit admin_mandate_path(locale: I18n.locale, id: user.mandate.id)
    expect {
      click_link I18n.t('activerecord.state_machines.events.reset')
      user.mandate.reload
    }.to change{user.mandate.documents}.to([])
  end

  it 'deletes the mandate signature' do
    visit admin_mandate_path(locale: I18n.locale, id: user.mandate.id)
    expect {
      click_link I18n.t('activerecord.state_machines.events.reset')
      user.mandate.reload
    }.to change{user.mandate.signature}.to(nil)
  end
end
