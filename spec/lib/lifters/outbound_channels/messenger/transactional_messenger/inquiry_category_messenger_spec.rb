# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Messenger::TransactionalMessenger::InquiryCategoryMessenger do
  let(:random_seed) { (rand * 100).floor + 1 }
  let(:inquiry_id) { random_seed }
  let(:category_ident) { "ident#{random_seed}" }
  let(:name) { "Customer Name#{random_seed}" }
  let(:company_name) { "Company Name#{random_seed}" }
  let(:category_name1) { "Category Name#{random_seed} 1" }
  let(:category_name2) { "Category Name#{random_seed} 2" }
  let(:category_names) { "#{category_name1}, #{category_name2}" }
  let(:key_singular_content) { "inquiry_cancellation_singular" }
  let(:key_plural_content) { "inquiry_cancellation_plural" }

  context "when cancelled by consultant" do
    context "when internationalized" do
      let(:singular_options) do
        {
          name:           name,
          company_name:   company_name,
          inquiry_id:     inquiry_id,
          category_ident: category_ident
        }
      end
      let(:singular_message) { I18n.t("messenger.#{key_singular_content}.content", singular_options) }
      let(:singular_cta_link) { I18n.t("messenger.#{key_singular_content}.cta_link", singular_options) }
      let(:singular_cta_text) { I18n.t("messenger.#{key_singular_content}.cta_text", singular_options) }
      let(:singular_cta_section) { I18n.t("messenger.#{key_singular_content}.cta_section", singular_options) }

      let(:plural_options) { {name: name, category_names: category_names} }
      let(:plural_message) { I18n.t("messenger.#{key_plural_content}.content", plural_options) }
      let(:plural_cta_link) { I18n.t("messenger.#{key_plural_content}.cta_link", plural_options) }
      let(:plural_cta_text) { I18n.t("messenger.#{key_plural_content}.cta_text", plural_options) }
      let(:plural_cta_section) { I18n.t("messenger.#{key_plural_content}.cta_section", plural_options) }

      current_locale = nil

      before do
        current_locale = I18n.locale
        I18n.locale = :de
      end

      after do
        I18n.locale = current_locale
      end

      it "should provide the singular message" do
        expect(singular_message).not_to match(/translation missing/)
      end

      it "should provide the singular message with the name" do
        expect(singular_message).to match(name)
      end

      it "should provide the singular message with the company name" do
        expect(singular_message).to match(company_name)
      end

      it "should provide the singular cta_link" do
        expected_link = "/app/manager/inquiries/#{inquiry_id}/category/#{category_ident}"
        expect(singular_cta_link).to eq(expected_link)
      end

      it "should provide the singular cta_text" do
        expect(singular_cta_text).not_to match(/translation missing/)
      end

      it "should provide the singular cta_section" do
        expect(singular_cta_section).not_to match(/translation missing/)
      end

      it "should provide the plural message" do
        expect(plural_message).not_to match(/translation missing/)
      end

      it "should provide the plural message with the name" do
        expect(plural_message).to match(name)
      end

      it "should provide the plural message with the category names" do
        expect(plural_message).to match(category_names)
      end

      it "should provide the plural cta_link" do
        expected_link = "/app/manager"
        expect(plural_cta_link).to eq(expected_link)
      end

      it "should provide the plural cta_text" do
        expect(plural_cta_text).not_to match(/translation missing/)
      end

      it "should provide the plural cta_section" do
        expect(plural_cta_section).not_to match(/translation missing/)
      end
    end

    context "messenger" do
      let(:messenger_class) { OutboundChannels::Messenger::TransactionalMessenger }
      let(:messenger) { instance_double(messenger_class) }
      let(:mandate) { instance_double(Mandate, id: random_seed, first_name: name) }
      let(:inquiry_category1) do
        instance_double(
          InquiryCategory,
          mandate:        mandate,
          name:           category_name1,
          company_name:   company_name,
          inquiry_id:     inquiry_id,
          category_ident: category_ident
        )
      end
      let(:inquiry_category2) do
        instance_double(
          InquiryCategory,
          mandate:        mandate,
          name:           category_name2,
          company_name:   company_name,
          inquiry_id:     inquiry_id,
          category_ident: category_ident
        )
      end

      context "successful message building" do
        before do
          allow(messenger_class).to receive(:new).with(any_args).and_return(messenger)
          allow(messenger).to receive(:send_message)
        end

        it "should create the cancellation message for one cancelled inquiry category" do
          expect(messenger_class)
            .to receive(:new)
            .with(
              mandate,
              key_singular_content,
              {
                name:           name, # customer's first name
                company_name:   company_name,
                inquiry_id:     inquiry_id,
                category_ident: category_ident
              },
              kind_of(Config::Options)
            )
            .and_return(messenger)
          messenger_class.inquiry_categories_cancelled(inquiry_category1)
        end

        it "should send the cancellation message for one cancelled inquiry category" do
          expect(messenger).to receive(:send_message)
          messenger_class.inquiry_categories_cancelled(inquiry_category1)
        end

        it "should create the cancellation message for multiple cancelled inquiry categories" do
          expect(messenger_class)
            .to receive(:new)
            .with(
              mandate,
              key_plural_content,
              {
                name:           name, # customer's first name
                category_names: category_names
              },
              kind_of(Config::Options)
            )
            .and_return(messenger)
          messenger_class.inquiry_categories_cancelled(inquiry_category1, inquiry_category2)
        end

        it "should send the cancellation message for multiple cancelled inquiry categories" do
          expect(messenger).to receive(:send_message)
          messenger_class.inquiry_categories_cancelled(inquiry_category1, inquiry_category2)
        end
      end

      context "errors" do
        it "should fail, if no inquiry categories are given" do
          expect {
            messenger_class.inquiry_categories_cancelled
          }.to raise_error("No inquiry categories given!")
        end

        it "should fail, if the inquiry categories are of different customers" do
          wrong_customer = instance_double(Mandate, id: random_seed + 1)
          allow(inquiry_category2).to receive(:mandate).and_return(wrong_customer)
          expect {
            messenger_class.inquiry_categories_cancelled(inquiry_category1, inquiry_category2)
          }.to raise_error("Two different mandates given! Ids: #{random_seed}, #{random_seed + 1}")
        end

        it "should fail, if the inquiry categories are of different companies" do
          allow(inquiry_category2).to receive(:company_name).and_return("Different Company")
          expect {
            messenger_class.inquiry_categories_cancelled(inquiry_category1, inquiry_category2)
          }.to raise_error("Two different companies given! Names: #{company_name}, Different Company")
        end
      end
    end
  end

  context "when cancelled by timeout" do
    let(:content_key) { "inquiry_cancellation_by_timeout" }

    context "when internationalized" do
      let(:options) do
        {
          name: name,
          company_name: company_name,
          inquiry_id: inquiry_id,
          category_ident: category_ident,
          category_name: category_name1
        }
      end
      let(:message) { I18n.t("messenger.#{content_key}.content", options) }
      let(:cta_link) { I18n.t("messenger.#{content_key}.cta_link", options) }
      let(:cta_text) { I18n.t("messenger.#{content_key}.cta_text", options) }
      let(:cta_section) { I18n.t("messenger.#{content_key}.cta_section", options) }

      current_locale = nil

      before do
        current_locale = I18n.locale
        I18n.locale = :de
      end

      after do
        I18n.locale = current_locale
      end

      it "should provide the message" do
        expect(message).not_to match(/translation missing/)
      end

      it "should provide the message with the name" do
        expect(message).to match(name)
      end

      it "should provide the message with the company name" do
        expect(message).to match(company_name)
      end

      it "should provide the cta_link" do
        expected_link = "/app/manager/inquiries/#{inquiry_id}/category/#{category_ident}"
        expect(cta_link).to eq(expected_link)
      end

      it "should provide the cta_text" do
        expect(cta_text).not_to match(/translation missing/)
      end

      it "should provide the cta_section" do
        expect(cta_section).not_to match(/translation missing/)
      end
    end

    context "messenger" do
      let(:messenger_class) { OutboundChannels::Messenger::TransactionalMessenger }
      let(:messenger) { instance_double(messenger_class) }
      let(:mandate) { instance_double(Mandate, id: random_seed, first_name: name) }
      let(:inquiry_category1) do
        instance_double(
          InquiryCategory,
          mandate:        mandate,
          name:           category_name1,
          company_name:   company_name,
          inquiry_id:     inquiry_id,
          category_ident: category_ident
        )
      end

      context "successful message building" do
        before do
          allow(messenger_class).to receive(:new).with(any_args).and_return(messenger)
          allow(messenger).to receive(:send_message)
        end

        it "should create the cancellation message for one cancelled inquiry category" do
          expect(messenger_class)
            .to receive(:new)
            .with(
              mandate,
              content_key,
              {
                name: name, # customer's first name
                company_name: company_name,
                inquiry_id: inquiry_id,
                category_ident: category_ident,
                category_name: category_name1
              },
              kind_of(Config::Options)
            )
            .and_return(messenger)
          messenger_class.inquiry_category_timed_out(inquiry_category1)
        end

        it "should send the cancellation message for one cancelled inquiry category" do
          expect(messenger).to receive(:send_message)
          messenger_class.inquiry_category_timed_out(inquiry_category1)
        end
      end

      context "errors" do
        it "should fail, if no inquiry categories are given" do
          expect {
            messenger_class.inquiry_category_timed_out(nil)
          }.to raise_error("No inquiry category given!")
        end
      end
    end
  end
end
