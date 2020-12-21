# frozen_string_literal: true

RSpec.shared_examples "csv_report" do |action|
  describe "##{action}" do
    before do
      allow(report_class).to(
        receive(:permitted_for?).and_return(permitted)
      )
    end

    context "when permission is granted" do
      let(:permitted) { true }

      it "sends report file" do
        expect(@controller).to receive(:send_data).with(any_args) { @controller.head :ok }
        get action, params: {locale: :de}
        expect(response.status).to eq(200)
      end
    end

    context "when permission isn't granted" do
      let(:permitted) { false }

      it "redirects back" do
        get action, params: {locale: :de}

        expect(controller).to set_flash[:alert].to(I18n.t("error.action_not_allowed"))
      end
    end
  end
end
