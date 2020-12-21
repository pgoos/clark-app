# frozen_string_literal: true

RSpec.shared_examples "password complexity" do
  describe "password complexity" do
    context "with valid password" do
      let(:password) { "Test1234" }

      it "returns successful result" do
        expect(subject).to be_success
      end
    end

    context "with invalid password" do
      context "when invalid length" do
        let(:password) { "abc" }

        it "returns password length validation error" do
          result = subject
          expect(result).not_to be_success

          min_length = Settings.password_complexity.user.length.from
          msg = I18n.t("errors.messages.too_short.other", count: min_length)
          expect(result.errors.to_h[:password]).to include(msg)
        end
      end

      context "when not complex enough" do
        let(:password) { "abc123456" }

        it "returns password not complex error" do
          result = subject
          expect(result).not_to be_success

          msg = I18n.t("activerecord.errors.models.user.password_complexity")
          expect(result.errors.to_h[:password]).to include(msg)
        end
      end
    end
  end
end
