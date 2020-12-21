# frozen_string_literal: true

require "rails_helper"

RSpec.describe Domain::InsuranceStatements::Situation do
  include_context "ensure locale is de"

  let(:mandate) { FactoryBot.build(:mandate) }
  let(:default_score) { Domain::InsuranceStatements::InsuranceStatement::DEFAULT_SCORE }
  let(:with_recommendation) { default_score.merge(recommendations_count: 1) }
  let(:with_product) { with_recommendation.merge(products_inquiries_count: 1) }

  describe "#[]" do
    subject { described_class.things(default_score) }

    context "known attribute" do
      it "can call methods with like hash keys" do
        expect(subject[:life_aspect]).to eq "things"
      end
    end

    context "unknown attributes" do
      it "should raise an attribute error" do
        expect { subject[:something_else] }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".things" do
    subject { described_class.things(with_recommendation) }

    it "should return an InsuranceStatements::Situation object" do
      expect(subject).to be_kind_of(Domain::InsuranceStatements::Situation)
    end

    describe "#life_aspect" do
      it "should be equal to 'things'" do
        expect(subject.life_aspect).to eq("things")
      end
    end

    describe "#title" do
      it "should return the translated life aspect name" do
        expect(subject.title).to eq("Besitz & Eigentum")
      end
    end

    describe "#text" do
      it "should return translated 'Empfohlene Versicherungen'" do
        expect(subject.text).to eq("Empfohlene Versicherungen")
      end
    end

    describe "#score" do
      context "no products or inquiries" do
        it "should calculate the score" do
          expect(subject.score).to eq("0 von 1")
        end
      end

      context "with products or inquiries" do
        subject { described_class.things(with_product) }


        it "should count the active products" do
          expect(subject.score).to eq("1 von 1")
        end
      end
    end
  end

  describe ".health" do
    subject { described_class.health(default_score) }

    it "should return an InsuranceStatements::Situation object" do
      expect(subject).to be_kind_of(Domain::InsuranceStatements::Situation)
    end

    describe "#life_aspect" do
      it "should be equal to 'health'" do
        expect(subject.life_aspect).to eq("health")
      end
    end

    describe "#title" do
      it "should return the translated life aspect name" do
        expect(subject.title).to eq("Gesundheit & Existenz")
      end
    end

    describe "#text" do
      it "should return translated 'Empfohlene Versicherungen'" do
        expect(subject.text).to eq("Empfohlene Versicherungen")
      end
    end

    describe "#score" do
      context "no products or inquiries" do
        subject { described_class.health(with_recommendation) }

        it "should calculate the score" do
          expect(subject.score).to eq("0 von 1")
        end
      end

      context "with products or inquiries" do
        subject { described_class.health(with_product) }

        it "should count the active products" do
          expect(subject.score).to eq("1 von 1")
        end
      end
    end

    describe "#rating" do
      context "more than or equal to 0.75" do
        subject { described_class.health(with_product) }

        it "should return 'Optimal'" do
          expect(subject.rating).to eq("Optimal")
        end
      end

      context "less than 0.75" do
        subject { described_class.health(with_recommendation) }

        it "should return 'Optimal'" do
          expect(subject.rating).to eq("Potential")
        end
      end
    end
  end

  describe ".retirement" do
    subject { described_class.retirement(mandate) }

    it "should return an InsuranceStatements::Situation object" do
      expect(subject).to be_kind_of(Domain::InsuranceStatements::Situation)
    end

    describe "#life_aspect" do
      it "should be equal to 'retirement'" do
        expect(subject.life_aspect).to eq("retirement")
      end
    end

    describe "#title" do
      it "should return the translated life aspect name" do
        expect(subject.title).to eq("Vorsorge")
      end
    end

    describe "#text" do
      it "should return the translated 'Renten-Prognose'" do
        expect(subject.text).to eq("Renten-Prognose")
      end
    end

    describe "#score" do
      let(:cockpit_double) { instance_double(Domain::Retirement::Cockpit) }

      before { allow(Domain::Retirement::Cockpit).to receive(:new).with(mandate).and_return(cockpit_double) }

      context "mandate has a retirement cockpit" do
        before do
          expected_response = Money.new(100_000, "EUR")
          allow(cockpit_double).to receive(:total_net_income).and_return(expected_response)
        end

        it "should return combined total gross income from cockpit" do
          expect(subject.score).to eq("1.000,00 €")
        end
      end

      context "mandate has no retirement cockpit" do
        before do
          allow(cockpit_double).to receive(:total_net_income).and_return(0)
        end

        it "should return a dash('-')" do
          expect(subject.score).to eq("-")
        end
      end
    end

    describe "#rating" do
      it "should return 'Potential'" do
        expect(subject.rating).to eq("Potential")
      end
    end
  end
end
