# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::MailPreviewController, :integration, type: :controller do
  let(:role)      { create(:role, permissions: Permission.where(controller: "admin/mail_preview")) }
  let(:admin)     { create(:admin, role: role) }
  let(:locale)    { I18n.locale }
  let(:recipient) { "admin@clark.de" }

  before { sign_in(admin) }

  describe "POST /templates" do
    let(:mailer)       { n_double("mailer") }
    let(:handler)      { n_double("handler", mail: mailer) }
    let(:preview_mail) { n_double("preview_mail") }
    let(:template)     { n_double("template", preview_mail: preview_mail, name: "template-name") }
    let(:templates)    { [template] }

    context "when successfully sent" do
      before do
        allow(RailsEmailPreview::Preview).to receive(:all).and_return(templates)
        allow(RailsEmailPreview::DeliveryHandler).to receive(:new).with(preview_mail, to: recipient).and_return(handler)
        allow(mailer).to receive(:deliver_now!)

        post :templates, params: {locale: locale, recipient: recipient}
      end

      it { is_expected.to use_before_action(:fetch_templates) }
      it { expect(mailer).to have_received(:deliver_now!) }
      it { is_expected.to set_flash[:notice] }
      it { is_expected.to redirect_to(rails_email_preview_path) }
    end

    context "when raises error" do
      before do
        allow(RailsEmailPreview::Preview).to receive(:all).and_return(templates)
        allow(RailsEmailPreview::DeliveryHandler).to receive(:new).with(preview_mail, to: recipient).and_return(handler)
        allow(mailer).to receive(:deliver_now!).and_raise(StandardError)

        post :templates, params: {locale: locale, recipient: recipient}
      end

      it { is_expected.to set_flash[:alert] }
      it { is_expected.to redirect_to(rails_email_preview_path) }
    end

    context "database transaction" do
      let(:records)   { 5 }
      let(:templates) { RailsEmailPreview::Preview.all.take(records) }

      before do
        allow(RailsEmailPreview::Preview).to receive(:all).and_return(templates)

        post :templates, params: {locale: locale, recipient: recipient}
      end

      it { expect { post :templates, params: {locale: locale, recipient: recipient} }.not_to change(Mandate, :count) }
    end
  end
end
