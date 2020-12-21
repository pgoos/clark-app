# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::Inquiries::GkvInquiryObserver do
  it "responds to gkv_inquiry_created" do
    expect(described_class).to respond_to(:gkv_inquiry_created)
  end

  context ".drop?" do
    let(:accepted_mandate) { n_instance_double(Inquiry, "accepted_mandate", mandate_accepted?: true) }
    let(:not_accepted_mandate) { n_instance_double(Inquiry, "accepted_mandate", mandate_accepted?: false) }

    it "returns true if the mandate is accepted" do
      expect(described_class).not_to be_drop(accepted_mandate)
    end

    it "returns false mandate is not accepted" do
      expect(described_class).to be_drop(not_accepted_mandate)
    end
  end

  context ".gkv_inquiry_created", :integration do
    let!(:company_count) { Company.count }
    let!(:subcompany_count) { Subcompany.count }
    let!(:category_count) { Category.count }
    let!(:plan_count) { Plan.count }

    let(:gkv_company) { create(:gkv_company) }
    let(:gkv_subcompany) { create(:subcompany, company: gkv_company) }
    let(:gkv) { create(:category_gkv) }
    let!(:gkv_plan) { create(:plan, subcompany: gkv_subcompany, category: gkv) }
    let(:accepted_mandate) { create(:mandate, :accepted) }
    let(:not_accepted_mandate) { create(:mandate, :created) }
    let(:inquiry) { create(:inquiry, mandate: accepted_mandate, company: gkv_company) }
    let(:not_processed_inquiry) { create(:inquiry, mandate: not_accepted_mandate, company: gkv_company) }

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it "creates the product", type: :job, skip: true do
      mandate_count = Mandate.count
      inquiry_count = Inquiry.count

      search_query = Product.by_company(gkv_company.id)

      expect(search_query.count).to eq(0)

      perform_enqueued_jobs { inquiry }

      fail_anyway = search_query.count != 1

      debugging_output = <<~EOT
        #########################################################################
        ##### Debugging output to inspect flakiness: ############################
        #########################################################################
        gkv company:
        #{gkv_company.attributes}
        #########################################################################
        gkv category:
        #{gkv.attributes}
        #########################################################################
        gkv plan:
        #{gkv_plan.attributes}
        #########################################################################
        accepted mandate:
        #{accepted_mandate.attributes}
        #########################################################################
        not accepted mandate:
        #{not_accepted_mandate.attributes}
        #########################################################################
        inquiry:
        #{inquiry.attributes}
        #########################################################################
        not processed inquiry:
        #{not_processed_inquiry.attributes}
        ---
        company count: #{Company.count}, initial count: #{company_count}
        subcompany count: #{Subcompany.count}, initial count: #{subcompany_count}
        category count: #{Category.count}, initial count: #{category_count}
        plan count: #{Plan.count}, initial count: #{plan_count}
        mandate count: #{Mandate.count}, initial count: #{mandate_count}
        inquiry count: #{Inquiry.count}, initial count: #{inquiry_count}
        #########################################################################

        Successful output in local execution (Quote!):

        > company count: 1, initial count: 0
        > subcompany count: 1, initial count: 0
        > category count: 1, initial count: 0
        > plan count: 1, initial count: 0
        > mandate count: 2, initial count: 0
        > inquiry count: 2, initial count: 0
        #########################################################################
      EOT
      puts debugging_output

      expect(search_query.count).to eq(1)

      perform_enqueued_jobs { not_processed_inquiry }
      expect(search_query.count).to eq(1)
      fail if fail_anyway
    end
  end
end
