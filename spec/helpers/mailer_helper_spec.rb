# frozen_string_literal: true

require "rails_helper"

RSpec.describe MailerHelper, type: :helper do
  let(:inquiry) { FactoryBot.build_stubbed(:inquiry) }
  let(:cockpit_fallback_path) { "manager" }

  def stub_inq_cat(trait, inquiry)
    FactoryBot.build_stubbed(:inquiry_category, trait, inquiry: inquiry)
  end

  before do
    @original_locale = I18n.locale
    I18n.locale = :de
  end

  after do
    I18n.locale = @original_locale
  end

  describe ".mailer_context_decorator" do
    it "returns class for decorator" do
      module DummyDecorator
      end
      allow(Settings.mailer).to receive(:context_decorator).and_return("DummyDecorator")
      expect(mailer_context_decorator).to eq DummyDecorator
    end
  end

  context "place holders" do
    context "[[anfragen_abbruch_benachrichtigung]]" do
      let(:token) { "[[anfragen_abbruch_benachrichtigung]]" }

      def expected_singular_text(inquiry)
        I18n.t(
          "activerecord.attributes.inquiry_category.cancellation_message.singular",
          company_name: inquiry.company_name
        )
      end

      def expected_plural_text(inquiry_categories)
        category_names = inquiry_categories.map(&:name).join(", ")
        I18n.t(
          "activerecord.attributes.inquiry_category.cancellation_message.plural",
          category_names: category_names
        )
      end

      it "has a localized singular message" do
        expect(expected_singular_text(inquiry)).not_to match(/translation missing/)
      end

      it "has a localized plural message" do
        inquiry_categories = [
          stub_inq_cat(:contract_not_found, inquiry),
          stub_inq_cat(:contract_not_found, inquiry)
        ]
        expect(expected_plural_text(inquiry_categories)).not_to match(/translation missing/)
      end

      it "should show the text for a single category" do
        @inquiry_categories = [stub_inq_cat(:contract_not_found, inquiry)]
        expect(html_content_with_subs(token)).to eq(expected_singular_text(inquiry))
      end

      it "should show the text for multiple categories" do
        @inquiry_categories = [
          stub_inq_cat(:contract_not_found, inquiry),
          stub_inq_cat(:contract_not_found, inquiry)
        ]
        expect(html_content_with_subs(token)).to eq(expected_plural_text(@inquiry_categories))
      end
    end
  end

  context "CTAs" do
    # rubocop:disable  Layout/LineLength
    def match_mail_cta(label, path)
      protocol     = Regexp.escape("http://")
      escaped_path = Regexp.escape(path)
      match(%r{<a class="mcnButton " [^>]*title="#{label}" [^>]*href=#{protocol}[^/ ]+#{escaped_path}[^>]*>#{label}</a>})
    end
    # rubocop:enable Layout/LineLength

    def match_mail_deeplink_cta(label, path)
      escaped_path = Regexp.escape(path)
      match(%r{<a class="mcnButton " [^>]*title="#{label}" [^>]*href=#{escaped_path}[^>]*>#{label}</a>})
    end

    context "#mc_button_inquiry_category" do
      let(:inquiry_category1) { stub_inq_cat(:contract_not_found, inquiry) }
      let(:inquiry_category2) { stub_inq_cat(:contract_not_found, inquiry) }
      let(:singular_label) do
        I18n.t("activerecord.attributes.inquiry_category.cancellation_message.singular_cta")
      end
      let(:plural_label) do
        I18n.t("activerecord.attributes.inquiry_category.cancellation_message.plural_cta")
      end

      it "should localize the singular cta" do
        expect(singular_label).not_to match(/translation missing/)
      end

      it "should localize the plural cta" do
        expect(plural_label).not_to match(/translation missing/)
      end

      it "should render the CTA for one inquiry category" do
        @inquiry_categories = [inquiry_category1]
        category_ident      = inquiry_category1.category_ident
        path = "manager/inquiries/#{inquiry.id}?category=#{category_ident}"
        expect(mc_button_inquiry_categories).to include(singular_label)
        expect(mc_button_inquiry_categories).to include(path)
      end

      it "should render the CTA for multiple inquiry categories" do
        @inquiry_categories = [inquiry_category1, inquiry_category2]
        expect(mc_button_inquiry_categories).to include(plural_label)
        expect(mc_button_inquiry_categories).to include(cockpit_fallback_path)
      end

      it "should render the CTA fallback if no categories given" do
        expect(mc_button_inquiry_categories).to include(plural_label)
        expect(mc_button_inquiry_categories).to include(cockpit_fallback_path)
      end
    end

    context "#mc_button_product" do
      let(:product) { FactoryBot.build_stubbed(:product) }
      let(:expected_text) { "Button Label #{rand.round(3)}" }

      # rubocop:disable RSpec/RepeatedExample
      it "should render the CTA for a product" do
        @product = product
        path = deeplink_url("manager/products/#{product.id}")
        expect(mc_button_product(expected_text)).to match_mail_deeplink_cta(expected_text, path)
      end
      # rubocop:enable RSpec/RepeatedExample

      # rubocop:disable RSpec/RepeatedExample
      it "should render the CTA fallback if no product" do
        @product = product
        path = deeplink_url("manager/products/#{product.id}")
        expect(mc_button_product(expected_text))
          .to match_mail_deeplink_cta(expected_text, path)
      end
      # rubocop:enable RSpec/RepeatedExample
    end

    describe "#current_or_random_admin" do
      context "appointment" do
        before do
          @appointment = FactoryBot.build(:appointment)
        end

        it "should return the appointment admin has a footer image" do
          admin = FactoryBot.build(:admin)
          allow(admin).to receive_message_chain("email_footer_image.present?")
            .and_return(true)

          @appointment.appointable.admin = admin
          expect(current_or_random_admin).to eq admin
        end

        context "appointable admin has no footer image" do
          it "should return a random low margin admin" do
            allow(@appointment.appointable.admin).to \
              receive_message_chain("email_footer_image.present?").and_return(false)

            expect(RoboAdvisor).to receive(:random_low_margin_admin).once
            current_or_random_admin
          end
        end
      end

      context "current admin" do
        before do
          @appointment = nil
          @current_admin = FactoryBot.build(:admin)
        end

        it "Return current admin if present and and has a footer image" do
          allow(@current_admin).to receive_message_chain("email_footer_image.present?")
            .and_return(true)
          expect(current_or_random_admin).to eq(@current_admin)
        end
      end

      context "default fallback" do
        before do
          @appointment = nil
          @current_admin = nil
        end

        it "should return a random low margin admin" do
          expect(RoboAdvisor).to receive(:random_low_margin_admin).once
          current_or_random_admin
        end
      end
    end

    context "when #mc_button_lead_restoration" do
      let(:encrypted_token) { "encryptedToken" }
      let(:expected_url) { "https://www.clark.de/s/sometoken" }

      before do
        allow_any_instance_of(ActiveSupport::MessageEncryptor).to receive(:encrypt_and_sign).and_return(encrypted_token)
        allow_any_instance_of(Platform::UrlShortener).to receive(:short_url).and_return(expected_url)
      end

      context "when lead is present" do
        let(:lead) { create(:lead) }

        before do
          lead
        end

        it "generates shortened url with restore token" do
          @mandate = lead.mandate
          generated_cta = mc_button_lead_restoration("restore session", "/mandate/profiling")
          expect(generated_cta).to include(expected_url)
          expect(generated_cta).to include("restore session")
        end
      end

      context "when lead is NOT present" do
        let(:user) { create(:user, mandate: create(:mandate)) }

        before do
          user
        end

        it "does not generate a shortened url with restore token" do
          @mandate = user.mandate
          generated_cta = mc_button_lead_restoration("restore session", "/mandate/profiling")
          expect(generated_cta).to include("restore session")
          expect(generated_cta).not_to include("/mandate/profiling")
        end
      end

      context "when neither user or lead is present" do
        it "the mandate invocation returns nil" do
          expect(mc_button_lead_restoration("restore session", "de/app/mandate/profiling")).to be_nil
        end
      end
    end
  end

  context "mc_decorate" do
    before { allow(Settings).to receive_message_chain(:emails, :formal_greetings) { formal_greetings } }

    let(:formal_greetings) { false }

    it "uses decorator if exists" do
      module DummyModule
        def self.mc_hero_options(root_url)
          {name: "mc_hero", redirect_url: root_url}
        end
      end
      allow(self).to receive(:mailer_context_decorator).and_return(DummyModule)
      expect(self).to receive(:render_template).with("mc_hero",
                                                     redirect_url: "http://test.host/")
      mc_hero
    end

    it "uses decorator if exists and pass 2 params" do
      module DummyModule
        def self.mc_greeting_short_options(customer_last_name, customer_gender)
          {
            name: "mc_greeting_short",
            customer_last_name: customer_last_name,
            customer_gender: customer_gender,
            salutation: "DummySalutation"
          }
        end
      end
      allow(self).to receive(:customer_last_name).and_return("Bob")
      allow(self).to receive(:customer_gender).and_return("male")
      allow(self).to receive(:mailer_context_decorator).and_return(DummyModule)
      expect(self).to receive(:render_template).with("mc_greeting_short",
                                                     customer_gender: "male",
                                                     customer_last_name: "Bob",
                                                     salutation: "DummySalutation")
      mc_greeting_short
    end

    it "calls original when decorator is nil" do
      allow(self).to receive(:mailer_context_decorator).and_return(nil)
      allow(self).to receive(:customer_first_name).and_return("Bob")
      allow(self).to receive(:customer_last_name).and_return("Smith")
      allow(self).to receive(:customer_gender).and_return("male")
      expect(self).to receive(:render_template).with(
        "mc_greeting_short",
        customer_first_name: "Bob",
        customer_last_name: "",
        greeting: "Hallo",
        salutation: ""
      )
      mc_greeting_short
    end

    context "when formal greetings are enabled" do
      let(:formal_greetings) { true }

      it "calls original when decorator is nil and formal greetins are enabled" do
        allow(self).to receive(:mailer_context_decorator).and_return(nil)
        allow(self).to receive(:customer_first_name).and_return("Bob")
        allow(self).to receive(:customer_last_name).and_return("Smith")
        allow(self).to receive(:customer_gender).and_return("male")
        expect(self).to receive(:render_template).with(
          "mc_greeting_short",
          customer_first_name: "Bob",
          customer_last_name: "Smith",
          greeting: "Sehr geehrter",
          salutation: "Herr"
        )
        mc_greeting_short
      end
    end
  end

  describe "#html_content_with_subs" do
    context "when working_text is [[product_termination_identifier]]" do
      let(:product) { create(:product, category: create(:category, name: "product_cateogry")) }
      let(:opportunity) { create(:opportunity, category: create(:category, name: "opportunity_cateogry")) }
      let(:working_text) { "[[product_termination_identifier]]" }

      context "when product and opportunity exist" do
        it "returns content with product and opportunity details" do
          @product = product
          @opportunity = opportunity

          html_content = html_content_with_subs(working_text).to_s

          expect(html_content).to match(Regexp.new(product.number))
          expect(html_content).to match(Regexp.new(product.plan_name))
          expect(html_content).to match(Regexp.new(product.category_name))
          expect(html_content).not_to match(Regexp.new(opportunity.category_name))
        end
      end

      context "when product exists and opportunity does not exists" do
        it "returns content with product details" do
          @product = product
          @opportunity = nil

          html_content = html_content_with_subs(working_text).to_s

          expect(html_content).to match(Regexp.new(product.number))
          expect(html_content).to match(Regexp.new(product.plan_name))
          expect(html_content).to match(Regexp.new(product.category_name))
        end
      end
    end

    context "working_text has [[termination_date]]" do
      let(:working_text) { "[[termination_date]]" }
      let(:product) { create(:product, category: create(:category, name: "product_cateogry")) }

      context "when product exists and it has contract_ended_at attribute" do
        it "return contract_ended_at" do
          @product = product
          product.contract_ended_at = Time.now
          expected = product.contract_ended_at.strftime("%d.%m.%Y")

          html_content = html_content_with_subs(working_text).to_s
          expect(html_content).to eq(expected)
        end
      end

      context "when product exists and it has annual_maturity attribute" do
        it "return contract_ended_at" do
          @product = product
          product.annual_maturity = { day: 1, month: 12 }
          expected = "1. #{I18n.t('mailers.months')[12]}"

          html_content = html_content_with_subs(working_text).to_s
          expect(html_content).to eq(expected)
        end
      end

      context "when product exists and it doesn't have contract_ended_at or annual_maturity attributes" do
        it "does not change working text" do
          @product = product
          @product.contract_ended_at = nil
          @product.annual_maturity   = nil

          html_content = html_content_with_subs(working_text).to_s
          expect(html_content).to eq(working_text)
        end
      end
    end
  end
end
