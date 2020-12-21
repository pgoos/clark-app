# == Schema Information
#
# Table name: comments
#
#  id               :integer          not null, primary key
#  admin_id         :integer
#  commentable_id   :integer
#  commentable_type :string
#  message          :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require "rails_helper"

RSpec.describe Comment, type: :model do
  #
  # Setup
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  subject { comment }

  let(:comment) do
    comment = build_stubbed(:comment)
    comment.admin = build_stubbed(:admin)
    comment.commentable = build_stubbed(:company)
    comment
  end

  it { is_expected.to be_valid }

  #
  # Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Constants
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Attribute Settings
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Plugins
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Concerns
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Index
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # State Machine
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Scopes
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Associations
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  it { is_expected.to belong_to(:admin) }

  it { is_expected.to belong_to(:commentable) }

  #
  # Nested Attributes
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #
  #
  # Validations
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  %i[admin_id commentable_id message].each do |attr|
    it { is_expected.to validate_presence_of(attr) }
  end

  #
  # Callbacks
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  it_behaves_like "a model with callbacks", :before, :create, :set_linked_message

  it_behaves_like "a model with callbacks", :after, :create, :set_admins!, :send_admin_mention

  #
  # Delegates
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Instance Methods
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  describe "#mentioned_emails" do
    subject { comment.mentioned_emails }

    context "when message contains email addresses" do
      before { comment.message = "I am admin1@test.clark.de and I am a friend of bdmin@test.clark.de!" }

      it { is_expected.to eq ["admin1@test.clark.de", "bdmin@test.clark.de"] }
    end

    context "when message contains no email addresses" do
      before { comment.message = "I am anonymous." }

      it { is_expected.to eq [] }
    end
  end

  describe "#mentioned_admins" do
    let!(:admin) { create(:admin) }
    subject { comment.mentioned_admins }

    context "when emails are mentioned" do
      before { allow(comment).to receive(:mentioned_emails).and_return([admin.email, "bdmin@test.clark.de"]) }

      it { is_expected.to eq [admin] }
    end

    context "when no emails are mentioned" do
      before { allow(comment).to receive(:mentioned_emails).and_return([]) }

      it { is_expected.to eq [] }
    end
  end

  describe "#linked_message" do
    subject { comment.linked_message }
    let(:message_with_email_address) { "This is a comment with an email@address.com and we want to see a link inserted if the email corresponds to an admin user." }
    before { comment.message = message_with_email_address }

    context "when no admins are mentioned" do
      before { allow(comment).to receive(:mentioned_admins).and_return([]) }

      it { is_expected.to eq(message_with_email_address) }
    end

    context "when an admin is mentioned" do
      let(:message_with_email_address_linked) { 'This is a comment with an <a href="' + Settings.mailer.asset_host + '/de/admin/admins/1">email@address.com</a> and we want to see a link inserted if the email corresponds to an admin user.' }
      before { allow(comment).to receive(:mentioned_admins).and_return([build(:admin, id: 1, email: 'email@address.com')]) }

      it { is_expected.to match(message_with_email_address_linked) }
    end
  end

  describe "#sanitize_message" do
    it "prevents xss injection" do
      message = "<script>alert(1);</script> hello i love your cookies"
      comment = build(:comment, message: message)
      comment.admin = create(:admin)
      comment.commentable = create(:company)
      comment.save
      expect(comment.message).to eq " hello i love your cookies"
    end
  end

  #
  # Class Methods
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Protected
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

  #
  # Private
  # ---------------------------------------------------------------------------------------
  #
  #
  #
  #

end
