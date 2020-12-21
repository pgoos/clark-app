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
#   feature 'The inquiry index feature' do
#
#     let!(:mandate) { create(:mandate, user: create(:user, password: 'password')) }
#     let!(:resource) { create(:inquiry, user: mandate.user, mandate: mandate, company_ids: create_list(:company, 5).map(&:id)) }
#     let(:expected_text) { [ resource.id,
#                             resource.user.email,
#                             'Pending',
#                             resource.company.name,
#                             I18n.l(resource.created_at, format: :number) ] }
#     let(:path) { admin_inquiries_path(locale: :en) }
#
#     it_behaves_like "an index feature"
#   end
#
#   feature 'The inquiry index feature nested in user' do
#
#     let!(:mandate) { create(:mandate, user: create(:user, password: 'password')) }
#     let!(:resource) { create(:inquiry, company: create(:company, name: 'TheCompany'), user: mandate.user, mandate: mandate) }
#     let(:expected_text) { [ resource.id,
#                             resource.user.email,
#                             'Pending',
#                             resource.company.name,
#                             I18n.l(resource.created_at, format: :number) ] }
#     let(:path) { admin_user_inquiries_path(resource.user, locale: :en) }
#
#     it_behaves_like "an index feature"
#   end
#
#   feature 'The inquiry create feature' do
#
#     let!(:company) { create(:company)}
#     let!(:user) { create(:user, password: 'password') }
#     let(:fill_ins) { {} }
#     let(:selects) { { inquiry_company_id: company.name } }
#     let(:checkboxes) { [] }
#     let(:expected_text) { [ user.email, 'Pending', company.name] }
#     let(:expected_input_values) { [] }
#     let(:path) { new_admin_user_inquiry_path(user, locale: :en) }
#
#     it_behaves_like "a create feature", Inquiry
#   end
#
#   feature 'The inquiry update feature' do
#
#     let!(:mandate) { create(:mandate, user: create(:user, password: 'password')) }
#     let!(:resource) { create(:inquiry, user: mandate.user, mandate: mandate, company_ids: [create(:company, name: 'TheCompany')]) }
#     let(:fill_ins) { {} }
#     let(:expected_text) { [ mandate.email, 'Pending', resource.company.name, I18n.l(resource.created_at, format: :number) ] }
#     let(:expected_input_values) { [] }
#     let(:path) { edit_admin_inquiry_path(resource, locale: :en) }
#
#     it_behaves_like "an update feature", Inquiry
#   end
#
#   feature 'The inquiry destroy feature' do
#
#     let!(:mandate) { create(:mandate, user: create(:user, password: 'password')) }
#     let!(:resource) { create(:inquiry, company: create(:company, name: 'TheCompany'), user: mandate.user, mandate: mandate) }
#     let(:index_path) { admin_inquiries_path(locale: :en) }
#     let(:delete_path) { admin_inquiry_path(resource, locale: :en) }
#
#     it_behaves_like "a destroy feature", Inquiry
#   end
# end
