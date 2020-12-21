# require 'rails_helper'
#
# feature 'Inquiry', :integration do
#
#   fixtures :permissions
#   fixtures :roles
#   fixtures :admins
#
#   before :each do
#     login_super_admin
#   end
#
#   feature 'The inquiry state machine feature' do
#
#     let!(:mandate) { create(:mandate, user: create(:user, password: 'password')) }
#     let!(:resource) { create(:inquiry, company_ids: create_list(:company, 3).map(&:id), user: mandate.user, mandate: mandate) }
#     let(:path) { admin_inquiry_path(resource, locale: :en) }
#     let(:events) { { inquire: 'Request information',
#                      cancel: 'Cancel request' } }
#     it_behaves_like "a state machine", Inquiry
#
#     let!(:mandate) { create(:mandate, user: create(:user, password: 'password')) }
#     let!(:resource) { create(:inquiry, company_ids: create_list(:company, 3).map(&:id), user: mandate.user, mandate: mandate) }
#     let(:path) { admin_inquiry_path(resource, locale: :en) }
#     let(:events) { { inquire: 'Request information',
#                      receive: 'Receive information',
#                      cancel: 'Cancel request' } }
#     it_behaves_like "a state machine", Inquiry
#
#     let!(:mandate) { create(:mandate, user: create(:user, password: 'password')) }
#     let!(:resource) { create(:inquiry, company_ids: create_list(:company, 3).map(&:id), user: mandate.user, mandate: mandate) }
#     let(:path) { admin_inquiry_path(resource, locale: :en) }
#     let(:events) { { inquire: 'Request information',
#                      receive: 'Receive information',
#                      approve_request: 'Approve request',
#                      cancel: 'Cancel request' } }
#     it_behaves_like "a state machine", Inquiry
#
#
#   end
# end
