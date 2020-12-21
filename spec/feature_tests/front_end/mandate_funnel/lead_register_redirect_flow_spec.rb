require "rails_helper"
require "./spec/support/features/page_objects/ember/mandate-funnel/lead_register_redirect_page"

RSpec.describe "Lead to register flow", :browser, type: :feature, js: true,
                                                  skip: "skipping again :(" do
  let(:locale) { I18n.locale }
  let(:page_object) { LeadToRegisterPage.new }

  let!(:lead) { create(:lead, mandate: create(:mandate)) }
  let!(:user) { create(:user, mandate: create(:mandate)) }

  describe 'as a lead' do
    context 'who has done confimring' do
      before(:each) do
        lead.mandate.info['wizard_steps'] = ['profiling', 'targeting', 'confirming']
        lead.mandate.signature            = create(:signature)
        lead.mandate.confirmed_at         = DateTime.current
        lead.mandate.tos_accepted_at      = DateTime.current
        lead.mandate.state                = :in_creation
        lead.mandate.save!

        login_as(lead, scope: :lead)
        page_object.visit_page()
      end

      it 'I should be redirected to register' do
        page_object.expect_on_register
      end

    end

    context 'who has not done confirming' do
      before(:each) do
        lead.mandate.info['wizard_steps'] = ['profiling', 'targeting']
        lead.mandate.state                = :in_creation
        lead.mandate.save!

        login_as(lead, scope: :lead)
        page_object.visit_page()
      end

      it 'I should not be redirected to register' do
        page_object.expect_on_cockpit
      end
    end
  end

  describe 'as a registred user' do
    context 'who has not done confirming' do
      before(:each) do
        user.mandate.info['wizard_steps'] = ['profiling', 'targeting']
        user.mandate.state                = :in_creation
        user.mandate.save!

        login_as(user, scope: :user)
        page_object.visit_page()
      end

      it 'I should not be redirected to register' do
        page_object.expect_on_cockpit
      end
    end

    context 'who has done confirming' do
      before(:each) do
        user.mandate.info['wizard_steps'] = ['profiling', 'targeting', 'confirming']
        user.mandate.signature            = create(:signature)
        user.mandate.confirmed_at         = DateTime.current
        user.mandate.tos_accepted_at      = DateTime.current
        user.mandate.state                = :in_creation
        user.mandate.complete
        user.mandate.accept!
        user.mandate.save!

        login_as(user, scope: :user)
        page_object.visit_page()
      end

      it 'I should not be redirected to register' do
        page_object.expect_on_cockpit
      end
    end
  end

end
