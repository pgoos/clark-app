# frozen_string_literal: true

require "spec_helper"
require "lifters/domain/products/reminder_params"

RSpec.describe Domain::Products::ReminderParams do
  let(:service) { described_class.new(product) }
  let(:company_ident) { "company123" }
  let(:mandate) { double("Mandate", first_name: "Arthur") }
  let(:company) { double("Company", ident: company_ident, name: "Cool Company") }
  let(:product) do
    double(
      "Product",
      id: 123,
      company: company,
      mandate: mandate,
      sold_by_us?: sold_by_us,
      category_name: "Category name",
      company_name: company.name,
      contract_ended_at?: contract_ended_at
    )
  end

  let(:expected_return) do
    {
      key: "contract_cancellation_reminder",
      mailer_options: {
        method: expected_reminder_method,
        params: [product.id]
      },
      messenger_options: {
        method: expected_reminder_method,
        params: [product]
      },
      push_options: {
        params: [
          product.mandate,
          expected_reminder_method,
          product,
          {
            category: product.category_name,
            company: company.name,
            first_name: product.mandate.first_name
          }
        ]
      }
    }
  end

  describe "#call" do
    shared_examples "a valid return" do
      it do
        expect(service.call("email", "message", "push")).to eq(expected_return)
      end
    end

    context "when company is one of the best insurer companies" do
      let(:sold_by_us) { false }
      let(:company_ident) { "huk2466e28b" }

      context "and contract_ended_at is known" do
        let(:contract_ended_at) { true }
        let(:expected_reminder_method) { :kfz_contract_cancellation_best_direct_insurer_known_end_date }

        it_behaves_like "a valid return"
      end

      context "and contract_ended_at is unknown" do
        let(:contract_ended_at) { false }
        let(:expected_reminder_method) { :kfz_contract_cancellation_best_direct_insurer_unknown_end_date }

        it_behaves_like "a valid return"
      end
    end

    context "when sold by us" do
      let(:sold_by_us) { true }

      context "and contract_ended_at is known" do
        let(:contract_ended_at) { true }
        let(:expected_reminder_method) { :notify_contract_cancellation_general_sold_by_us_known_end_date }

        it_behaves_like "a valid return"
      end

      context "and contract_ended_at is unknown" do
        let(:contract_ended_at) { false }
        let(:expected_reminder_method) { :notify_contract_cancellation_general_sold_by_us_unknown_end_date }

        it_behaves_like "a valid return"
      end
    end

    context "when sold by others" do
      let(:sold_by_us) { false }

      context "and contract_ended_at is known" do
        let(:contract_ended_at) { true }
        let(:expected_reminder_method) { :notify_contract_cancellation_general_sold_by_others_known_end_date }

        it_behaves_like "a valid return"
      end

      context "and contract_ended_at is unknown" do
        let(:contract_ended_at) { false }
        let(:expected_reminder_method) { :notify_contract_cancellation_general_sold_by_others_unknown_end_date }

        it_behaves_like "a valid return"
      end
    end

    context "when is not a valid channel" do
      let(:sold_by_us) { true }
      let(:contract_ended_at) { true }

      it "raises an error" do
        expect {
          service.call("nope")
        }.to raise_error(ArgumentError, '"nope" is not a valid channel')
      end
    end

    context "when is a valid channel" do
      let(:sold_by_us) { true }
      let(:contract_ended_at) { true }

      it "returns valid params" do
        {
          "email" => {
            key: "contract_cancellation_reminder",
            mailer_options: {
              method: :notify_contract_cancellation_general_sold_by_us_known_end_date,
              params: [product.id]
            }
          },
          "message" => {
            key: "contract_cancellation_reminder",
            messenger_options: {
              method: :notify_contract_cancellation_general_sold_by_us_known_end_date,
              params: [product]
            }
          },
          "push" => {
            key: "contract_cancellation_reminder",
            push_options: {
              params: [
                product.mandate,
                :notify_contract_cancellation_general_sold_by_us_known_end_date,
                product,
                {
                  category: product.category_name,
                  company: company.name,
                  first_name: product.mandate.first_name
                }
              ]
            }
          }
        }.each { |channel, expected_return| expect(service.call(channel)).to eq(expected_return) }
      end
    end
  end
end
