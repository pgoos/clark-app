# frozen_string_literal: true

require "rails_helper"

describe "rake reoccurring_advice:filter", type: :task do
  let(:category) { create(:category_phv) }

  before { Timecop.freeze(Time.current) }

  after  { Timecop.return }

  context "with feature switch turned on" do
    let(:mailer)     { double(ActionMailer::Base, attachments: {}, deliver_now: true) }
    let(:filename)   { "reoccurring_advice_#{Time.zone.now}.log" }
    let(:job_double) { double(ReoccurringAdviceJob) }

    before { allow(Features).to receive(:active?).and_return(true) }

    context "with eligible products" do
      before do
        allow(ReoccurringAdviceJob).to receive(:set)
          .with(priority: 0, wait: when_to_run)
          .and_return(job_double)
      end

      context "when weekdays" do
        let(:when_to_run) { 0 }
        let!(:eligible_product) do
          create(:product,
                 :with_advice,
                 state: :details_available,
                 category: category,
                 contract_ended_at: 4.months.from_now)
        end

        before do
          allow(ActionMailer::Base).to receive(:mail)
            .with(from: Settings.emails.service,
                  to: Settings.robo.auditors.emails,
                  subject: "Reoccurring advice CRON for Robo Advisor: #{filename}",
                  body: "siehe Attachment").and_return(mailer)

          allow(job_double).to receive(:perform_later).with(eligible_product.id)
          allow(Tasks::Common::Utils).to receive(:when_to_run).and_return(0)
        end

        it do
          task.invoke
          expect(job_double).to have_received(:perform_later).with(eligible_product.id)
        end
      end

      context "when weekends" do
        let(:when_to_run) { Time.zone.local(2019, 1, 7, 9, 0) - running_date }
        let(:eligible_product) do
          create(:product,
                 :with_advice,
                 state: :details_available,
                 category: category,
                 contract_ended_at: 4.months.from_now)
        end

        before do
          Timecop.freeze(running_date)
          allow(job_double).to receive(:perform_later).with(eligible_product.id)
        end

        after { Timecop.return }

        context "when saturday" do
          let(:running_date) { Time.zone.local(2019, 1, 5, 9, 0) }

          it do
            task.invoke
            expect(job_double).to have_received(:perform_later)
          end
        end

        context "when sunday" do
          let(:running_date) { Time.zone.local(2019, 1, 6, 9, 0) }

          it do
            task.invoke
            expect(job_double).to have_received(:perform_later)
          end
        end
      end
    end
  end

  context "with feature switch turned off" do
    before { allow(Features).to receive(:active?).and_return(false) }

    context "with eligible products" do
      let!(:eligible_product) do
        create(:product,
               :with_advice,
               state: :details_available,
               category: category,
               contract_ended_at: 4.months.ago)
      end

      it do
        expect(ReoccurringAdviceJob).not_to receive(:perform_later).with(eligible_product.id)

        task.invoke
      end
    end
  end

  context "with ineligible products" do
    let!(:ineligible_products) do
      create_list(:product,
                  3,
                  :with_advice,
                  state: :details_available,
                  category: category,
                  contract_ended_at: 3.months.ago)
    end

    before { allow(Features).to receive(:active?).and_return(true) }

    it do
      ineligible_products.each do |product|
        expect(ReoccurringAdviceJob).not_to receive(:perform_later).with(product.id)
      end

      task.invoke
    end
  end
end
