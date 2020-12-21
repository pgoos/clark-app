# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Products::NotifyKfzContractCancellation do
  let(:notifier) { double(call: true) }
  let(:repository) { class_double("ProductsRepository") }
  let(:service) { described_class.new(notifier, Settings.kfz_contract_cancellation_reminder, repository) }

  before { Timecop.freeze(current_date) }

  after { Timecop.return }

  describe "daily notification" do
    let(:current_date) { Date.new(2020, 7, 2) }

    it "calls the repository" do
      reminder_date = Date.current + 120.days
      expect(repository)
        .to receive(:retrieve_kfz_products_eligible_for_cancellation_notification).with(reminder_date).and_return([])

      service.call
    end

    context "when there are products" do
      let(:product) { OpenStruct.new(id: 1, mandate_id: 1001, category_name: "pkv") }
      let(:products) { [product] }

      before do
        allow(repository).to receive(:retrieve_kfz_products_eligible_for_cancellation_notification).and_return(products)
      end

      it "calls notifier" do
        expect(notifier).to receive(:call).with(product.id)

        service.call
      end
    end

    context "when there are no products" do
      let(:products) { [] }

      before do
        allow(repository).to receive(:retrieve_kfz_products_eligible_for_cancellation_notification).and_return(products)
      end

      it "does not call notifier" do
        expect(notifier).not_to receive(:call)

        service.call
      end
    end
  end

  describe "motor_switching_season_notification" do
    context "when is first batch day" do
      let(:current_date) { Date.new(2020, 10, 1) }

      it "calls repository" do
        expect(repository)
          .to receive(:retrieve_first_batch_kfz_products_for_cancellation_notification).and_return([])

        service.call
      end

      context "when there are products" do
        let(:product) { OpenStruct.new(id: 1, mandate_id: 1001, category_name: "pkv") }
        let(:products) { [product] }

        before do
          allow(repository)
            .to receive(:retrieve_first_batch_kfz_products_for_cancellation_notification).and_return(products)
        end

        it "calls notifier" do
          expect(notifier).to receive(:call).with(product.id)

          service.call
        end
      end

      context "when there are no products" do
        let(:products) { [] }

        before do
          allow(repository)
            .to receive(:retrieve_first_batch_kfz_products_for_cancellation_notification).and_return(products)
        end

        it "does not call notifier" do
          expect(notifier).not_to receive(:call)

          service.call
        end
      end
    end

    context "when is second bach day" do
      let(:current_date) { Date.new(2020, 10, 7) }

      it "calls repository" do
        expect(repository)
          .to receive(:retrieve_second_batch_kfz_products_for_cancellation_notification).and_return([])

        service.call
      end

      context "when there are products" do
        let(:product) { OpenStruct.new(id: 1, mandate_id: 1001, category_name: "pkv") }
        let(:products) { [product] }

        before do
          allow(repository)
            .to receive(:retrieve_second_batch_kfz_products_for_cancellation_notification).and_return(products)
        end

        it "calls notifier" do
          expect(notifier).to receive(:call).with(product.id)

          service.call
        end
      end

      context "when there are no products" do
        let(:products) { [] }

        before do
          allow(repository)
            .to receive(:retrieve_second_batch_kfz_products_for_cancellation_notification).and_return(products)
        end

        it "does not call notifier" do
          expect(notifier).not_to receive(:call)

          service.call
        end
      end
    end
  end
end
