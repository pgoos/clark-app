# frozen_string_literal: true

RSpec.shared_examples "a phv rule" do |advice_persona, non_advice_persona, plan_idents|
  let(:mandate) { create(:mandate) }
  let(:insurance_comparison) do
    create(:insurance_comparison, opportunity: opportunity, mandate: mandate)
  end
  let(:opportunity) { create(:opportunity, mandate: mandate) }
  let(:valid_options) do
    {
      opportunity:             opportunity,
      insurance_comparison_id: insurance_comparison.id,
      mandate:                 mandate
    }
  end
  let(:subject) { described_class.new(valid_options) }
  let(:plan_mapping) do
    random_seed = rand(100)
    namespace = Sales::Rules::PhvRule
    {
      namespace::HAFTPFLICHTKASSE_EINFACH_KOMPLETT => {
        ident:        namespace::HAFTPFLICHTKASSE_EINFACH_KOMPLETT,
        name:         "#{random_seed} Einfach Komplett",
        company_name: "Haftpflichtkasse"
      },
      namespace::VHV_KLASSIK_GARANT_EXKLUSIV       => {
        ident:        namespace::VHV_KLASSIK_GARANT_EXKLUSIV,
        name:         "#{random_seed} VHV Klassik-Garant",
        company_name: "VHV"
      },
      namespace::AXA_BOXFLEX_PREMIUM_VERMIETUNG    => {
        ident:        namespace::AXA_BOXFLEX_PREMIUM_VERMIETUNG,
        name:         "#{random_seed} BOXflex Premium",
        company_name: "AXA"
      },
      namespace::INTERRISK_XXL_NICHT_SCHADENFREI   => {
        ident:        namespace::INTERRISK_XXL_NICHT_SCHADENFREI,
        name:         "#{random_seed} InterRisk (nicht schadenfrei)",
        company_name: "InterRisk"
      }
    }
  end
  let(:plan_result) { [] }

  it { expect(Sales::Rules::PhvRule.available_rules).to include(described_class) }

  before do
    allow(subject).to receive(:with_schade_modifier).and_return("")

    allow(Plan)
      .to receive_message_chain(:active, :where)
      .with(ident: plan_idents)
      .and_return(plan_result)

    plan_attributes = plan_mapping.select { |ident, _| plan_idents.include?(ident) }.values
    plan_attributes.each do |attr|
      plan_result << instance_double(Plan, attr)
    end
  end

  context "phv rule for #{advice_persona} / #{non_advice_persona} / #{plan_idents.inspect}" do
    context "#new" do
      context "with valid options" do
        it { expect(subject.opportunity).to eq(opportunity) }
        it { expect(subject.mandate).to eq(opportunity.mandate) }
        it { expect(subject.insurance_comparison_id).to eq(insurance_comparison.id) }
      end

      context "without valid options" do
        it "raise ArgumentError if no options are passed" do
          expect { described_class.new }.to raise_error(ArgumentError)
        end

        it "raise ArgumentError if options are not a hash" do
          expect { described_class.new("not a hash") }.to raise_error(ArgumentError)
        end
      end
    end

    context "#name" do
      it "has a meaningful name" do
        expect(subject.name).not_to be_blank
        expect(subject.name).to match(/PHV/)
      end
    end

    context "#applicable?" do
      context "with a valid matching situation" do
        before do
          allow(subject).to receive(:user_situation).and_return(send(advice_persona))
          allow(subject).to receive(:situation_valid?).and_return(true)
        end

        it{ expect(subject).to be_applicable }
      end

      context "without a invalid situation" do
        before do
          allow(subject).to receive(:user_situation).and_return(send(advice_persona))
          allow(subject).to receive(:situation_valid?).and_return(false)
        end

        it{ expect(subject).not_to be_applicable }
      end

      context "with a valid non-matching situation" do
        before do
          allow(subject).to receive(:user_situation).and_return(send(non_advice_persona))
          allow(subject).to receive(:situation_valid?).and_return(true)
        end

        it{ expect(subject).not_to be_applicable }
      end
    end

    context "#offer_attributes" do
      before do
        allow(subject).to receive(:user_situation).and_return(send(advice_persona))
      end

      it { expect(subject.offer_attributes.count).to eq(3) }

      it "has the right plan, option_type and requirement " do
        subject.offer_attributes.each_with_index do |option, index|
          expect(option.keys).to contain_exactly(:option_type,
                                                    :recommended,
                                                    :company,
                                                    :tarif)
          expected_plan_attributes = plan_mapping[plan_idents[index]]
          expect(option[:tarif]).to eq(expected_plan_attributes[:name])
          expect(option[:company]).to eq(expected_plan_attributes[:company_name])
        end
      end

      it "should raise an exception, if the plan is not found" do
        allow(Plan).to receive_message_chain(:active, :where).with(ident: plan_idents).and_return([])

        error_format = %r{Plan\(s\) not found \/ inactive: \[[^\s]+, [^\s]+, [^\s]+\]}

        expect {
          subject.offer_attributes
        }.to raise_error(match(error_format))
      end
    end
  end
end
