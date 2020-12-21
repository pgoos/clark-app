# frozen_string_literal: true

# == Schema Information
#
# Table name: opportunities
#
#  id                 :integer          not null, primary key
#  mandate_id         :integer
#  admin_id           :integer
#  source_id          :integer
#  source_type        :string
#  source_description :string
#  category_id        :integer
#  state              :string
#  old_product_id     :integer
#  sold_product_id    :integer
#  offer_id           :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  is_automated       :boolean          default(FALSE)
#  metadata           :jsonb
#  followup_situation :string           default(NULL)
#

require "rails_helper"

RSpec.describe Opportunity, type: :model do
  subject { build :opportunity, mandate: mandate, category: category, admin: nil }

  let(:mandate) { build :mandate }
  let(:category) { build :category }

  it_behaves_like "an auditable model"
  it_behaves_like "a commentable model"

  describe "#loss_reasons=" do
    it "accepts nil" do
      expect { subject.loss_reason = nil }.not_to raise_error
    end

    it "accepts valid values" do
      expect { subject.loss_reason = Opportunity::LOSS_REASONS["fake"] }.not_to raise_error
    end

    it "do not accept invalid values" do
      expect { subject.loss_reason = "bla" }.to raise_error Dry::Types::ConstraintError
    end
  end

  describe "#loss_reason" do
    it { is_expected.to respond_to :loss_reason }
  end

  context "create callbacks" do
    describe "#send_opportunity_initiated_to_salesforce" do
      it "sends to salesforce when opportunity created in initiation phase" do
        allow(Settings.salesforce).to receive(:enable_send_opportunity_events).and_return(true)
        mock_lamda = ->(args) { args }
        allow(::Salesforce::Container).to receive(:resolve)
          .with("public.interactors.perform_send_event_job")
          .and_return(mock_lamda)

        expect(::Salesforce::Container).to receive(:resolve)

        category.margin_level = "high"
        create(:opportunity, :initiation_phase, mandate: mandate, category: category, admin: nil)
      end
    end
  end

  describe "Broadcast AOA update events" do
    let!(:admin) { create(:admin) }
    let(:created_opp_with_admin) { create(:opportunity, :created, admin: admin) }
    let(:created_opp_with_no_admin) { create(:opportunity, :created, admin: nil) }
    let(:initiation_opp_with_admin) { create(:opportunity, :initiation_phase, admin: admin) }
    let(:initiation_opp_with_no_admin) { create(:opportunity, :initiation_phase, admin: nil) }
    let(:offer_phase_opp_with_admin) { create(:opportunity, :offer_phase, admin: admin) }
    let(:offer_phase_opp_with_no_admin) { create(:opportunity, :offer_phase, admin: nil) }
    let(:lost_opp_with_no_admin) { create(:opportunity, :lost, admin: nil) }
    let(:lost_opp_with_admin) { create(:opportunity, :lost, admin: admin) }
    let(:completed_opp_with_no_admin) { create(:opportunity, :completed, admin: nil) }
    let(:completed_opp_with_admin) { create(:opportunity, :completed, admin: admin) }

    context "on opportunity creation" do
      context "with state created" do
        it "broadcasts only open_leads_count_changed if with admin" do
          expect {
            created_opp_with_admin
          }.to broadcast(:open_leads_count_changed, admin.id).and not_broadcast(:revenue_changed)
        end

        it "doesn't broadcast if without admin" do
          expect {
            created_opp_with_no_admin
          }.to not_broadcast(:open_leads_count_changed).and not_broadcast(:revenue_changed)
        end
      end

      context "with state initiation_phase" do
        it "broadcasts only open_leads_count_changed if with admin" do
          expect {
            initiation_opp_with_admin
          }.to broadcast(:open_leads_count_changed, admin.id).and not_broadcast(:revenue_changed)
        end

        it "doesn't broadcast if without admin" do
          expect {
            initiation_opp_with_no_admin
          }.to not_broadcast(:open_leads_count_changed).and not_broadcast(:revenue_changed)
        end
      end

      context "with state offer_phase" do
        it "broadcasts only open_leads_count_changed if with admin" do
          expect {
            offer_phase_opp_with_admin
          }.to broadcast(:open_leads_count_changed, admin.id).and not_broadcast(:revenue_changed)
        end

        it "doesn't broadcast if without admin" do
          expect {
            offer_phase_opp_with_no_admin
          }.to not_broadcast(:open_leads_count_changed).and not_broadcast(:revenue_changed)
        end
      end

      context "with state lost" do
        it "doesn't broadcast if with admin" do
          expect {
            lost_opp_with_admin
          }.to not_broadcast(:open_leads_count_changed).and not_broadcast(:revenue_changed)
        end

        it "doesn't broadcast if without admin" do
          expect {
            lost_opp_with_no_admin
          }.to not_broadcast(:open_leads_count_changed).and not_broadcast(:revenue_changed)
        end
      end

      context "with state completed" do
        it "broadcasts revenue_changed and but not open_leads_count_changed if with admin" do
          expect {
            completed_opp_with_admin
          }.to not_broadcast(:open_leads_count_changed).and broadcast(:revenue_changed, admin.id)
        end

        it "doesn't broadcast if without admin" do
          expect {
            completed_opp_with_no_admin
          }.to not_broadcast(:open_leads_count_changed).and not_broadcast(:revenue_changed)
        end
      end
    end

    context "on opportunity update" do
      context "change admin" do
        context "assign admin" do
          it "broadcasts only open_leads_count_changed if state is created" do
            created_opp_with_no_admin
            expect {
              created_opp_with_no_admin.update(admin_id: admin.id)
            }.to broadcast(:open_leads_count_changed, admin.id).and not_broadcast(:revenue_changed)
          end

          it "broadcasts only open_leads_count_changed if state is initiation_phase" do
            initiation_opp_with_no_admin
            expect {
              initiation_opp_with_no_admin.update(admin_id: admin.id)
            }.to broadcast(:open_leads_count_changed, admin.id).and not_broadcast(:revenue_changed)
          end

          it "broadcasts only open_leads_count_changed if state is offer_phase" do
            offer_phase_opp_with_no_admin
            expect {
              offer_phase_opp_with_no_admin.update(admin_id: admin.id)
            }.to broadcast(:open_leads_count_changed, admin.id).and not_broadcast(:revenue_changed)
          end

          it "doesn't broadcast if state is lost" do
            lost_opp_with_no_admin
            expect {
              lost_opp_with_no_admin.update(admin_id: admin.id)
            }.to not_broadcast(:open_leads_count_changed, admin.id).and not_broadcast(:revenue_changed)
          end

          it "broadcasts revenue_changed but not open_leads_count_changed if state is completed" do
            completed_opp_with_no_admin
            expect {
              completed_opp_with_no_admin.update(admin_id: admin.id)
            }.to not_broadcast(:open_leads_count_changed, admin.id).and broadcast(:revenue_changed, admin.id)
          end
        end

        context "re-assign admin" do
          let!(:second_admin) { create(:admin) }

          it "broadcasts only open_leads_count_changed if state is created" do
            created_opp_with_admin
            expect {
              created_opp_with_admin.update(admin_id: second_admin.id)
            }.to broadcast(:open_leads_count_changed, admin.id)
              .and broadcast(:open_leads_count_changed, second_admin.id)
              .and not_broadcast(:revenue_changed)
          end

          it "broadcasts only open_leads_count_changed if state is initiation_phase" do
            initiation_opp_with_admin
            expect {
              initiation_opp_with_admin.update(admin_id: second_admin.id)
            }.to broadcast(:open_leads_count_changed, admin.id)
              .and broadcast(:open_leads_count_changed, second_admin.id)
              .and not_broadcast(:revenue_changed)
          end

          it "broadcasts only open_leads_count_changed if state is offer_phase" do
            offer_phase_opp_with_admin
            expect {
              offer_phase_opp_with_admin.update(admin_id: second_admin.id)
            }.to broadcast(:open_leads_count_changed, admin.id)
              .and broadcast(:open_leads_count_changed, second_admin.id)
              .and not_broadcast(:revenue_changed)
          end

          it "doesn't broadcast if state is lost" do
            lost_opp_with_admin
            expect {
              lost_opp_with_admin.update(admin_id: second_admin.id)
            }.to not_broadcast(:open_leads_count_changed)
              .and not_broadcast(:open_leads_count_changed)
              .and not_broadcast(:revenue_changed)
          end

          it "broadcasts revenue_changed but not open_leads_count_changed if state is completed" do
            completed_opp_with_admin
            expect {
              completed_opp_with_admin.update(admin_id: second_admin.id)
            }.to not_broadcast(:open_leads_count_changed)
              .and broadcast(:revenue_changed, admin.id)
              .and broadcast(:revenue_changed, second_admin.id)
          end
        end
      end

      context "change state" do
        let(:sold_product) { create(:product) }

        def add_advisory_documentation
          create(:document, documentable: sold_product, document_type: DocumentType.advisory_documentation)
        end

        context "with admin" do
          it "broadcasts only open_leads_count_changed if state changed from created to initiation_phase" do
            created_opp_with_admin
            expect {
              created_opp_with_admin.assign
            }.to broadcast(:open_leads_count_changed, admin.id).and not_broadcast(:revenue_changed)
          end

          it "broadcasts only open_leads_count_changed if state changed from initiation_phase to offer_phase" do
            initiation_opp_with_admin
            expect {
              initiation_opp_with_admin.send_offer
            }.to not_broadcast(:open_leads_count_changed, admin.id).and not_broadcast(:revenue_changed)
          end

          it "broadcasts open_leads_count_changed but not revenue_changed if state changed from offer_phase to lost" do
            offer_phase_opp_with_admin
            expect {
              offer_phase_opp_with_admin.cancel
            }.to broadcast(:open_leads_count_changed, admin.id).and not_broadcast(:revenue_changed, admin.id)
          end

          it "broadcasts open_leads_count_changed and revenue_changed if state changed from offer_phase to completed" do
            offer_phase_opp_with_admin.sold_product = sold_product
            add_advisory_documentation
            expect {
              offer_phase_opp_with_admin.complete
            }.to broadcast(:open_leads_count_changed, admin.id).and broadcast(:revenue_changed, admin.id)
          end
        end

        context "without admin" do
          it "doesn't broadcast if state changed from created to initiation_phase" do
            created_opp_with_no_admin
            expect {
              created_opp_with_no_admin.assign
            }.to not_broadcast(:open_leads_count_changed).and not_broadcast(:revenue_changed)
          end

          it "doesn't broadcast if state changed from initiation_phase to offer_phase" do
            initiation_opp_with_no_admin
            expect {
              initiation_opp_with_no_admin.send_offer
            }.to not_broadcast(:open_leads_count_changed).and not_broadcast(:revenue_changed)
          end

          it "doesn't broadcast if state changed from offer_phase to lost" do
            offer_phase_opp_with_no_admin
            expect {
              offer_phase_opp_with_no_admin.cancel
            }.to not_broadcast(:open_leads_count_changed).and not_broadcast(:revenue_changed)
          end

          it "doesn't broadcast if state changed from offer_phase to completed" do
            offer_phase_opp_with_no_admin.sold_product = sold_product
            add_advisory_documentation
            expect {
              offer_phase_opp_with_no_admin.complete
            }.to not_broadcast(:open_leads_count_changed).and not_broadcast(:revenue_changed)
          end
        end
      end
    end
  end

  # State Machine
  context "when state machine changes state" do
    context "when emitting an event to salesforce" do
      before do
        allow(Settings.salesforce).to receive(:enable_send_opportunity_events).and_return(true)
      end

      context "when category is of high margin" do
        it "should send event to salesforce" do
          mock_lamda = ->(args) { args }
          allow(::Salesforce::Container).to receive(:resolve)
            .with("public.interactors.perform_send_event_job")
            .and_return(mock_lamda)

          expect(::Salesforce::Container).to receive(:resolve)
          subject.category.margin_level = "high"
          subject.assign
        end
      end

      context "when category is disallowed" do
        it "should not send event to salesforce" do
          expect(::Salesforce::Container).not_to receive(:resolve)
          subject.category.ident = "84a5fba0"
          subject.assign
        end
      end

      context "when category is GKV" do
        it "should not send event to salesforce" do
          expect(::Salesforce::Container).not_to receive(:resolve)
          subject.category.ident = "3659e48a"
          subject.assign
        end
      end

      context "when category is of low margin" do
        it "should send event to salesforce" do
          allow(Settings.salesforce).to receive(:enable_send_opportunity_events).and_return(true)
          expect(::Salesforce::Container).not_to receive(:resolve)
          subject.category.margin_level = "low"
          subject.assign
        end
      end
    end

    context "when state machine is in initial state (created)" do
      let(:admin) { create :admin }

      it "is created in created state" do
        expect(Opportunity.new).to be_created
      end

      it "should not receive a sold product" do
        expect(subject).not_to be_should_receive_a_sold_product
      end

      it "can be moved to initiation phase" do
        expect(subject.assign).to be_truthy
        expect(subject).to be_initiation_phase
      end

      describe "#salesforce" do
        context "when transitioned to the initiated state" do
          it "should emit Salesforce job" do
            subject.save
            expect_any_instance_of(Opportunity).to receive(:send_opportunity_initiated_to_salesforce)

            subject.assign
          end
        end

        context "when transitioned to the offer created state" do
          it "emits event to salesforce" do
            allow(Settings.salesforce).to receive(:enable_send_opportunity_events).and_return(true)
            expect_any_instance_of(Opportunity).to receive(:send_opportunity_offer_created_to_salesforce)
            subject.send_offer
          end
        end
      end

      it "triggering creation of 'sales_consultant_assigned' business event" do
        expect_any_instance_of(Opportunity)
          .to receive(:track_sales_consultant_assigned)

        subject.assign
      end

      it "triggering creation of 'sales_consultant_assigned'" do
        expect(Raven)
          .not_to receive(:capture_exception)

        subject.assign(admin, nil)
      end

      it "can be set to lost" do
        expect(subject.cancel).to be_truthy
        expect(subject).to be_lost
      end

      it "can be set to offer phase" do
        expect(subject.send_offer).to be_truthy
        expect(subject).to be_offer_phase
      end

      it "cannot be transitioned to other states" do
        expect(subject.complete).to be_falsey
      end
    end

    context "initiation_phase" do
      before { subject.state = "initiation_phase" }

      it "should not receive a sold product" do
        expect(subject).not_to be_should_receive_a_sold_product
      end

      it "can be moved to offer phase" do
        expect(subject.send_offer).to be_truthy
        expect(subject).to be_offer_phase
      end

      it "can be set to lost" do
        expect(subject.cancel).to be_truthy
        expect(subject).to be_lost
      end

      it "cannot be transitioned to other states" do
        expect(subject.assign).to be_falsey
        expect(subject.complete).to be_falsey
      end

      context "when opportunity has interactions" do
        let(:mandate) { create(:mandate) }
        let(:incoming_interaction) { create(:interaction, direction: "in", mandate: mandate) }
        let(:outgoing_interaction) { create(:interaction, direction: "out", mandate: mandate) }

        before do
          subject.interactions << incoming_interaction
          subject.interactions << outgoing_interaction
          subject.save
        end

        it "acknowledges the incoming interaction automatically when sending offer" do
          expect(subject.interactions.acknowledged).to eq(Interaction.none)
          subject.send_offer
          expect(subject.interactions.acknowledged).to eq([incoming_interaction])
        end
      end
    end

    context "offer phase" do
      let(:sold_product) { create(:product) }

      def add_advisory_documentation
        create(:document, documentable: sold_product, document_type: DocumentType.advisory_documentation)
      end

      before do
        subject.state = "offer_phase"
      end

      it "should receive a sold product" do
        expect(subject).to be_should_receive_a_sold_product
      end

      it "can be moved to completed, if a sold product is present" do
        add_advisory_documentation
        subject.sold_product = sold_product
        expect(subject.complete).to be_truthy
        expect(subject).to be_completed
      end

      it "can be moved to completed, if a sold product is passed as parameter" do
        add_advisory_documentation
        expect(subject.complete(sold_product)).to be_truthy
        expect(subject).to be_completed
      end

      it "#successfully_sold event is broad-casted with opportunity id when moved to completed" do
        subject.id = rand(1..100)
        add_advisory_documentation
        subject.sold_product = sold_product
        expect { subject.complete }.to broadcast(:successfully_sold, subject)
      end

      context "when opportunity is set to cancel" do
        it "should emit Salesforce job" do
          allow(Settings.salesforce).to receive(:enable_send_opportunity_events).and_return(true)
          expect_any_instance_of(Opportunity).to receive(:send_opportunity_lost_to_salesforce)
          subject.cancel
        end
      end

      it "cannot be moved to completed without a sold product" do
        expect(subject.complete).to be_falsey
        expect(subject).to be_offer_phase
      end

      it "cannot be moved to completed with a sold product, that is missing the advisory documentation" do
        expect(subject.complete(sold_product)).to be_falsey
        expect(subject).to be_offer_phase
      end

      it "can be set to lost" do
        expect(subject.cancel).to be_truthy
        expect(subject).to be_lost
      end

      it "cannot be transitioned to other states" do
        expect(subject.assign).to be_falsey
        expect(subject.send_offer).to be_falsey
      end
    end

    context "lost" do
      before { subject.state = "lost" }

      it "should not receive a sold product" do
        expect(subject).not_to be_should_receive_a_sold_product
      end

      it "cannot be transitioned to other states" do
        expect(subject.assign).to be_falsey
        expect(subject.send_offer).to be_falsey
        expect(subject.complete).to be_falsey
        expect(subject.cancel).to be_falsey
      end
    end

    context "with an offer" do
      let(:sold_product) { create(:product, :with_advisory_documentation) }
      let(:active_offer) do
        create(
          :active_offer,
          offer_options: [
            FactoryBot.build(:offer_option, recommended: true),
            FactoryBot.build(:offer_option),
            FactoryBot.build(:offer_option, product: sold_product)
          ]
        )
      end

      before do
        subject.offer = active_offer
        subject.state = "offer_phase"
        subject.sold_product = sold_product
        subject.save!
      end

      it "fails to complete, if an active offer is attached" do
        expect(subject.complete).to be_falsey
        expect(ProductMailer).not_to receive(:advisory_documentation_available)
      end

      context "does not fail with inactive offer" do
        before do
          active_offer.state = :inactive
        end

        it "sends e-mail about advisory documentation" do
          expect(ProductMailer).to \
            receive(:advisory_documentation_available).and_return(ActionMailer::Base::NullMail.new)

          expect(subject.complete).to be_truthy
        end
      end
    end

    context "completed" do
      before { subject.state = "completed" }

      it "should receive a sold product" do
        expect(subject).to be_should_receive_a_sold_product
      end
    end

    context "transition hooks" do
      it "destroys follow ups when set to lost" do
        subject.follow_ups << FactoryBot.build(:follow_up)
        expect do
          subject.cancel
        end.to change { subject.follow_ups.size }.from(1).to(0)
      end

      it "destroys follow ups when set to completed" do
        subject.state = "offer_phase"
        subject.follow_ups << FactoryBot.build(:follow_up)

        expect do
          subject.cancel
        end.to change { subject.follow_ups.size }.from(1).to(0)
      end

      it "cancels the offer when the opportunity is set to lost" do
        subject.state = "offer_phase"
        subject.offer = FactoryBot.build(:offer, state: "active")
        subject.follow_ups << FactoryBot.build(:follow_up)

        expect do
          subject.cancel
        end.to change { subject.offer.state }.from("active").to("canceled")
      end

      it "sets the admin on assign" do
        admin = FactoryBot.build(:admin)
        subject.admin = nil

        expect do
          subject.assign(admin)
        end.to change(subject, :admin).from(nil).to(admin)
      end

      it "sets the sold product on complete" do
        product = FactoryBot.build(:product)
        subject.state = "offer_phase"

        expect do
          subject.complete(product)
        end.to change(subject, :sold_product).from(nil).to(product)
      end

      it "marks questionnaires as read when the opportunity is set to offer phase" do
        subject.state = "initiation_phase"
        interaction = Interaction::AnsweredQuestionnaire.create(mandate: subject.mandate, topic: subject, questionnaire_response_id: 4711)

        expect do
          subject.send_offer
          interaction.reload
        end.to change { interaction.acknowledged }.from(false).to(true)
      end
    end
  end

  # Scopes

  describe ".by_warmup_call_status" do
    let(:opportunity_successful_warmup_call) { create(:opportunity) }
    let(:opportunity_unsuccessful_warmup_call) { create(:opportunity) }
    let!(:opportunity_no_warmup_call) { create(:opportunity) }
    let!(:successful_warmup_call) { create(:sales_warmup_call, :successful, topic: opportunity_successful_warmup_call, mandate: opportunity_successful_warmup_call.mandate) }
    let!(:unsuccessful_warmup_call) { create(:sales_warmup_call, :unsuccessful, topic: opportunity_unsuccessful_warmup_call, mandate: opportunity_unsuccessful_warmup_call.mandate) }

    it "returns only opportunities with succesful warmup calls when called with successful status" do
      expect(Opportunity.by_warmup_call_status(Interaction::PhoneCall.call_states[:successful].to_s)).to eq([opportunity_successful_warmup_call])
    end

    it "returns only opportunities with unsuccesful warmup calls when called with unsuccessful status" do
      expect(Opportunity.by_warmup_call_status(Interaction::PhoneCall.call_states[:unsuccessful].to_s)).to eq([opportunity_unsuccessful_warmup_call])
    end

    it "returns only opportunities with no warmup calls when called with not attempted status" do
      expect(Opportunity.by_warmup_call_status(Interaction::PhoneCall.call_states[:not_attempted].to_s)).to eq([opportunity_no_warmup_call])
    end
  end

  # Associations

  it { expect(subject).to belong_to(:mandate) }
  it { expect(subject).to belong_to(:source) }
  it { expect(subject).to belong_to(:category) }
  it { expect(subject).to belong_to(:old_product) }
  it { expect(subject).to belong_to(:sold_product) }
  it { expect(subject).to belong_to(:offer).dependent(:destroy) }
  it { expect(subject).to belong_to(:admin) }
  it { expect(subject).to have_many(:interactions).dependent(:destroy) }
  it { expect(subject).to have_many(:insurance_comparisons).dependent(:destroy) }
  it { expect(subject).to have_many(:appointments).dependent(:destroy) }
  it { expect(subject).to have_many(:product_partner_data) }

  # Nested Attributes

  # Validations

  context "mandate" do
    before do
      mandate.phone = "069 123123123"
    end

    Mandate.state_machine.states.keys.except(:revoked).each do |valid_state|
      it "should be valid, if the mandate's state is #{valid_state}" do
        mandate.state = valid_state
        expect(subject).to be_valid
      end
    end

    it "should not be valid, if the mandate is revoked and opportunity is active" do
      mandate.state = :revoked

      expect(mandate).to be_revoked
      expect(subject).not_to be_valid
    end

    it "should be valid, if the mandate is revoked and opportunity is getting lost" do
      mandate.state = :revoked
      subject.state = :lost

      expect(mandate).to be_revoked
      expect(subject).to be_valid
    end

    it "should provide a comprehensible validation error message for revoked customers" do
      mandate.state = :revoked
      subject.valid?
      error_message = I18n.t("admin.opportunities.errors.mandate_state")
      expect(subject.errors.messages[:mandate]).to include(error_message)
    end

    it "should provide a translation for the error message for revoked customers" do
      mandate.state = :revoked
      subject.valid?
      error_message = I18n.t("admin.opportunities.errors.mandate_state")
      expect(error_message).not_to match(/translation/)
    end
  end

  context "sold product" do
    before { subject.sold_product = build(:product) }

    it "allows to add a sold product, if there's no offer attached" do
      expect(subject).to be_valid
    end

    it "does not allow to add a product not in the offer as sold product" do
      subject.offer = build(:active_offer)
      expect(subject).not_to be_valid
    end
  end

  context "level" do
    it "should NOT be valid if level is blank" do
      subject.level = nil
      expect(subject).not_to be_valid
    end

    it "should NOT be valid if level doesn't belongs to the enum" do
      expect { subject.level = "s" }.to raise_exception
    end
  end

  # Callbacks

  # Delegates

  it { is_expected.to delegate_method(:category_ident).to(:category).as(:ident) }
  it { is_expected.to delegate_method(:offer_active?).to(:offer).as(:active?) }
  it { is_expected.to delegate_method(:admin_first_name).to(:admin).as(:first_name) }

  # Instance Methods

  it { expect(described_class.new).not_to be_automated }

  describe "#offer_automation_available?" do
    context "categories" do
      {
        "03b12732" => "PHV",
        "5bfa54ce" => "legal protection",
        "e251294f" => "household property",
        "47a1b441" => "residential property"
        # TODO: add missing categories
      }.each do |category_ident, category_acronym|
        it "should be true for the category #{category_ident} / #{category_acronym}" do
          category = FactoryBot.build(:category, ident: category_ident)
          subject.category = category
          expect(subject.offer_automation_available?).to eq(true)
        end
      end

      it "should be false for an arbitrary category" do
        category = FactoryBot.build(:category, ident: "arbitrary_category")
        subject.category = category
        expect(subject.offer_automation_available?).to eq(false)
      end
    end

    context "mandate states" do
      let(:mandate) { FactoryBot.build(:mandate) }

      before do
        subject.category = FactoryBot.build(:category, ident: "03b12732")
        subject.mandate = mandate
      end

      mandate_states_for_offers = %i[
        in_creation
        created
        accepted
      ]

      mandate_states_no_offer = Mandate.state_machine.states.keys.except(*mandate_states_for_offers)

      mandate_states_for_offers.each do |state|
        it "should be true for the mandate state #{state}" do
          mandate.state = state.to_s # stored as string in db
          expect(subject.offer_automation_available?).to eq(true)
        end
      end

      mandate_states_no_offer.each do |state|
        it "should be true for the mandate state #{state}" do
          mandate.state = state.to_s # stored as string in db
          expect(subject.offer_automation_available?).to eq(false)
        end
      end
    end
  end

  context "category" do
    it "knows the category's coverage features (delegate)" do
      expect(subject.category.coverage_features).not_to be_empty
      expect(subject.coverage_features).to eq(subject.category.coverage_features)
    end

    it "can check it's category against another" do
      expect(subject).to be_matches_category(subject.category)
    end

    it "can check it's category against another and returns false for a different" do
      other = instance_double(Category, ident: "wrong_ident")
      expect(subject).not_to be_matches_category(other)
    end

    it "does not match the category, if nil is given" do
      expect(subject).not_to be_matches_category(nil)
    end

    it "raises an exception, if the owned category is nil" do
      other = instance_double(Category)
      subject.category = nil
      expect {
        subject.matches_category?(other)
      }.to raise_error("Opportunity has no category!")
    end
  end

  context "partner_offer" do
    let(:mandate) { create(:mandate, state: :accepted) }
    let(:old_product) { create(:product, mandate: mandate, premium_price_cents: 11_000, premium_price_currency: "EUR", premium_period: :year) }

    before do
      subject.mandate = mandate
      subject.old_product = old_product
      subject.category = old_product.category
      subject.save
    end

    it "should return the partner offer, if chosen" do
      offer = create(:product_partner_datum, product: old_product, state: :chosen)
      expect(subject.partner_offer).to eq(offer)
    end

    it "should return nothing, if there offer is deferred" do
      create(:product_partner_datum, product: old_product, state: :deferred)
      expect(subject.partner_offer).to be_nil
    end

    it "should return nothing, if there offer is imported" do
      create(:product_partner_datum, product: old_product, state: :imported)
      expect(subject.partner_offer).to be_nil
    end

    it "should return nothing, if there offer is cancelled" do
      create(:product_partner_datum, product: old_product, state: :cancelled)
      expect(subject.partner_offer).to be_nil
    end

    it "should return the partner offer, if purchase_pending" do
      offer = create(:product_partner_datum, product: old_product, state: :purchase_pending)
      expect(subject.partner_offer).to eq(offer)
    end
  end

  context "offer via product partner" do
    it "knows, if it is related to a product partner for a chosen partner datum" do
      product_partner_datum = double(ProductPartnerDatum)
      allow(subject).to receive(:partner_offer).and_return(product_partner_datum)
      expect(subject).to be_via_product_partner
    end

    it "knows, if it is not offered via a product partner" do
      expect(subject).not_to be_via_product_partner
    end

    it "knows, if it is related to a product partner for a purchase_pending partner datum" do
      product_partner_datum = double(ProductPartnerDatum)
      allow(subject).to receive(:partner_offer).and_return([product_partner_datum])
      expect(subject).to be_via_product_partner
    end
  end

  describe "#warmup_call_status" do
    it "returns not_attempted if no sales warm up call found in the interactions" do
      expect(subject.warmup_call_status).to eq(:not_attempted)
    end

    it "returns successful if the last sales warm up call found in the interactions and was in reached state" do
      create(:interaction_phone_call, call_type: Interaction::PhoneCall.call_types[:sales_warmup],
                         status: Interaction::PhoneCall::STATUS_REACHED, topic: subject)
      expect(subject.warmup_call_status).to eq(:successful)
    end

    it "returns unsuccessful if the last sales warm up call found in the interactions and was in not reached state" do
      create(:interaction_phone_call, call_type: Interaction::PhoneCall.call_types[:sales_warmup],
                         status: Interaction::PhoneCall::STATUS_NOT_REACHED, topic: subject)
      expect(subject.warmup_call_status).to eq(:unsuccessful)
    end

    it "returns unsuccessful if the last sales warm up call found in the interactions and was in need follow up state" do
      create(:interaction_phone_call, call_type: Interaction::PhoneCall.call_types[:sales_warmup],
                         status: Interaction::PhoneCall::STATUS_NEED_FOLLOW_UP, topic: subject)
      expect(subject.warmup_call_status).to eq(:unsuccessful)
    end

    it "returns successful if more than one sales warm up call found in the interactions and the last one was in reached state" do
      create(:interaction_phone_call, call_type: Interaction::PhoneCall.call_types[:sales_warmup],
                         status: Interaction::PhoneCall::STATUS_NEED_FOLLOW_UP, topic: subject)
      create(:interaction_phone_call, call_type: Interaction::PhoneCall.call_types[:sales_warmup],
                         status: Interaction::PhoneCall::STATUS_REACHED, topic: subject)
      expect(subject.warmup_call_status).to eq(:successful)
    end
  end

  # Class Methods

  describe ".first_consultant_assigned_for_high_margin" do
    let(:high_margin_category) { create(:category, ident: Category::HIGH_MARGIN_CATEGORIES.first) }
    let(:high_margin_opportunity) { create(:opportunity, category: high_margin_category) }
    let(:mandate) { create(:mandate) }
    let(:admin) { create(:admin) }

    it "returns the first admin assigned to high margin opportunity for a selected mandate" do
      high_margin_opportunity.mandate = mandate
      high_margin_opportunity.admin = admin
      high_margin_opportunity.save
      expect(described_class.first_consultant_assigned_for_high_margin(mandate.id)).to eq(admin)
    end

    it "returns nil if mandate has no opportunities" do
      mandate = create(:mandate)
      expect(described_class.first_consultant_assigned_for_high_margin(mandate.id)).to be_nil
    end

    it "returns only the admin attached to high margin opportunity" do
      second_admin = create(:admin)
      create(:opportunity, admin: second_admin, mandate: mandate)
      high_margin_opportunity.mandate = mandate
      high_margin_opportunity.admin = admin
      high_margin_opportunity.save
      expect(described_class.first_consultant_assigned_for_high_margin(mandate.id)).to eq(admin)
    end
  end

  describe ".source_types" do
    it "returns unique source types" do
      source_types = described_class.source_types
      expect(source_types.length).to eq(source_types.uniq.length)
    end
  end

  context "when opportunity is high margin" do
    it "sets default followup situation" do
      category = create(:category, ident: Category::HIGH_MARGIN_CATEGORIES.first)
      opportunity = described_class.new category: category
      expect(opportunity.followup_situation).to eq "warmup_call"
    end
  end

  context "when opportunity is not high margin" do
    it "does not set default followup situation" do
      opportunity = described_class.new category: create(:category_gkv)
      expect(opportunity.followup_situation).to eq nil
    end
  end

  describe "#old_product_canceled?" do
    context "when has old product" do
      let(:opportunity) { create :opportunity, old_product: product }

      context "when it's canceled" do
        let(:product) { create :product, state: :canceled }

        it { expect(opportunity).to be_old_product_canceled }
      end

      context "when it's not canceled" do
        let(:product) { create :product, state: :order_pending }

        it { expect(opportunity).not_to be_old_product_canceled }
      end
    end
  end

  describe "#send_adjust_hm_opportunity_created_48h_event" do
    it "send tracking event to adjust" do
      expect { create(:opportunity) }.to broadcast(:send_adjust_hm_opportunity_created_48h)
    end
  end
end
