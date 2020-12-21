# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClarkAPI::V2::Inquiries, :integration do
  let(:mandate) { create(:mandate) }
  let(:user) { create(:user, mandate: mandate) }
  let(:user_no_mandate) { create(:user) }

  context "GET /api/inquiries/:id" do
    let(:inquiry) { create(:inquiry, mandate: mandate) }

    it "gets the inquiry associated with the mandate" do
      login_as(user, scope: :user)
      json_get_v2 "/api/inquiries/#{inquiry.id}"
      expect(response.status).to eq(200)
    end

    context "with an inquiry that has multiple categories" do
      let!(:category_one) { create(:category) }
      let!(:category_two) { create(:category) }
      let!(:inquiry_with_categories) { create(:inquiry, categories: [category_one, category_two], mandate: user.mandate) }

      it "returns an array of the category names hyphenated" do
        login_as(user, scope: :user)
        json_get_v2 "/api/inquiries/#{inquiry_with_categories.id}"

        expect(response.status).to eq(200)
        expect(json_response.category_names).to include(word_hypen(category_one.name), word_hypen(category_two.name))
      end

      it "returns an array of the category idents" do
        login_as(user, scope: :user)
        json_get_v2 "/api/inquiries/#{inquiry_with_categories.id}"

        expect(response.status).to eq(200)
        expect(json_response.category_idents).to include(category_one.ident, category_two.ident)
      end
    end

    context "with an inquiry that is not associated with the user" do
      let!(:other_inquiry) { create(:inquiry, mandate: create(:mandate)) }

      it "does not allow the user to access the inquiry data" do
        login_as(user, scope: :user)
        json_get_v2 "/api/inquiries/#{other_inquiry.id}"
        expect(response.status).to eq(404)
      end
    end

    it "states that the inquiry is not older than five days" do
      login_as(user, scope: :user)
      json_get_v2 "/api/inquiries/#{inquiry.id}"
      expect(response.status).to eq(200)
      expect(json_response.under_five_days).to eq(true)
    end

    it "returns 401 if the user is not singed in" do
      json_get_v2 "/api/inquiries/#{inquiry.id}"
      expect(response.status).to eq(401)
    end

    it "returns nil for the average response time where there is none" do
      login_as(user, scope: :user)
      inquiry.company.update_attributes(average_response_time: nil)
      json_get_v2 "/api/inquiries/#{inquiry.id}"
      expect(response.status).to eq(200)
      expect(json_response.company.average_response_time).to eq(nil)
    end

    context "Company data about the inquiry" do
      let!(:company) { create(:company, name: "Company name one") }
      let!(:inquiry) { create(:inquiry, mandate: user.mandate, company: company) }

      it "gets the related company for the inquiry" do
        login_as(user, scope: :user)
        json_get_v2 "/api/inquiries/#{inquiry.id}"
        expect(response.status).to eq(200)
        expect(json_response.company.name).to eq("Company name one")
      end

      it "shows that the company works with us" do
        login_as(user, scope: :user)
        json_get_v2 "/api/inquiries/#{inquiry.id}"
        expect(response.status).to eq(200)
        expect(json_response.blacklist).to eq(false)
      end
    end

    context "a company that is not working with us" do
      let!(:company) do
        create(:company, name: "Company name one",
                         id: 208,
                         ident: "deuts5eca37",
                         inquiry_blacklisted: true)
      end
      let!(:inquiry) { create(:inquiry, mandate: user.mandate, company: company) }

      it "returns false if the company does not work with us" do
        login_as(user, scope: :user)
        json_get_v2 "/api/inquiries/#{inquiry.id}"
        expect(response.status).to eq(200)
        expect(json_response.blacklist).to eq(true)
      end
    end

    context "an inquiry that is older than five days" do
      let!(:inquiry) { create(:inquiry, mandate: user.mandate, created_at: 6.days.ago) }

      it "states that the inquiry is older than five days" do
        login_as(user, scope: :user)
        json_get_v2 "/api/inquiries/#{inquiry.id}"
        expect(response.status).to eq(200)
        expect(json_response.under_five_days).to eq(false)
      end
    end

    context "an inquiry with an average response time" do
      let!(:company) { create(:company, name: "Company name one", average_response_time: 10) }
      let!(:inquiry) { create(:inquiry, mandate: user.mandate, company: company) }

      it "returns the response time in days" do
        login_as(user, scope: :user)
        json_get_v2 "/api/inquiries/#{inquiry.id}"
        expect(response.status).to eq(200)
        expect(json_response.company.average_response_time).to eq(10)
      end
    end
  end

  context "POST /api/inquiries" do
    # Some samples for creating inquies with
    let(:company_one) { create(:company) }
    let(:company_two) { create(:company) }
    let(:category) { create(:category) }

    context "not logged in" do
      it "should throw a validation error" do
        json_post_v2 "/api/inquiries", inquiries: [{category_id: category.id, company_id: company_one.id}]
        expect(response.status).to eq(401)
      end
    end

    context "no mandate" do
      it "should throw a validation error" do
        login_as(user_no_mandate, scope: :user)
        json_post_v2 "/api/inquiries", inquiries: [{category_id: category.id, company_id: company_one.id}]
        expect(response.status).to eq(401)
      end
    end

    context "logged in with mandate" do
      before { login_as(user, scope: :user) }

      it "should create inquiries with categories" do
        json_post_v2 "/api/inquiries", inquiries: [{category_id: category.id, company_id: company_one.id}]
        expect(response.status).to eq(201)
        expect(json_response.success).to eq("created the inquiries")
      end

      it "should NOT require a category for every inquiry" do
        json_post_v2 "/api/inquiries", inquiries: [{category_id: category.id, company_id: company_one.id}, {company_id: company_two.id}]
        expect(response.status).to eq(201)
        expect(json_response.success).to eq("created the inquiries")
      end

      it "should require a company for every inquiry" do
        json_post_v2 "/api/inquiries", inquiries: [{category_id: category.id}]
        expect(response.status).to eq(500)
      end

      it "should send newly added inquiries to the insurers" do
        job = double :job, perform_later: nil

        Timecop.freeze(Time.zone.now) do
          expect(SendNewlyAddedInquiriesJob).to \
            receive(:set).with(wait_until: 15.minutes.from_now).and_return job

          expect(job).to receive(:perform_later)

          json_post_v2 "/api/inquiries",
                       inquiries: [
                         {category_id: category.id, company_id: company_one.id}
                       ]
        end
      end
    end
  end

  context "DELETE /api/inquiries/:id/:category_ident" do
    let(:inquiry) { create(:inquiry, mandate: user.mandate) }
    let!(:category_one) { create(:category) }
    let!(:category_two) { create(:category) }

    context "without" do
      it "performs cancellation" do
        login_as(user, scope: :user)
        json_delete_v2 "/api/inquiries/#{inquiry.id}/no_inquiry_category"

        expect(response.status).to eq 204
        expect(inquiry.reload).to be_canceled
      end
    end

    context "with an inquiry that has multiple inquiry_categories" do
      let!(:inquiry_category1) do
        create(:inquiry_category, category: category_one, inquiry: inquiry)
      end

      let!(:inquiry_category2) do
        create(:inquiry_category, category: category_two, inquiry: inquiry)
      end

      it "rejects an unauthorized request" do
        json_delete_v2 "/api/inquiries/#{inquiry.id}/#{category_one.ident}"
        expect(response.status).to eq(401)
      end

      it "cancels inquiry_category" do
        login_as(user, scope: :user)
        json_delete_v2 "/api/inquiries/#{inquiry.id}/#{category_one.ident}"
        expect(response.status).to eq(204)
        expect(inquiry.reload).not_to be_canceled
        expect(inquiry_category1.reload).to be_cancelled
        expect(inquiry_category1.cancellation_cause).to eq "cancelled_by_customer"
      end

      it "cancels an inquiry_category and the inquiry itself when there is no inquiry_category active" do
        login_as(user, scope: :user)

        json_delete_v2 "/api/inquiries/#{inquiry.id}/#{category_one.ident}"
        expect(response.status).to eq(204)
        expect(inquiry_category1.reload).to be_cancelled

        json_delete_v2 "/api/inquiries/#{inquiry.id}/#{category_two.ident}"
        expect(response.status).to eq(204)
        expect(inquiry_category2.reload).to be_cancelled

        expect(inquiry.reload).to be_canceled
      end
    end
  end

  context "POST /api/inquiries/:id/:category_ident/documents" do
    context "with an inquiry that has multiple categories" do
      let!(:category_one) { create(:category) }
      let!(:category_two) { create(:category) }
      let!(:inquiry_with_categories) { create(:inquiry, categories: [category_one, category_two], mandate: user.mandate) }

      let(:file) do
        fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "blank.pdf"))
      end

      it "should attach a file to an inquiry category" do
        login_as(user, scope: :user)
        post_v2 "/api/inquiries/#{inquiry_with_categories.id}/#{category_one.ident}/documents", file: [file]
        inquiry_category = inquiry_with_categories.inquiry_categories.find_by(category_id: category_one.id)
        expect(inquiry_category.documents.size).to eq(1)
      end

      it "should attach multiple files to an inquiry category" do
        login_as(user, scope: :user)
        post_v2 "/api/inquiries/#{inquiry_with_categories.id}/#{category_one.ident}/documents", file: [file, file]
        inquiry_category = inquiry_with_categories.inquiry_categories.find_by(category_id: category_one.id)
        expect(inquiry_category.documents.size).to eq(2)
      end

      it "should reject an upload by non authenticated user" do
        post_v2 "/api/inquiries/#{inquiry_with_categories.id}/#{category_one.ident}/documents", file: [file]
        inquiry_category = inquiry_with_categories.inquiry_categories.find_by(category_id: category_one.id)
        expect(inquiry_category.documents.size).to eq(0)
      end
    end
  end
end
