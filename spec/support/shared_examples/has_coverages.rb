# frozen_string_literal: true

RSpec.shared_examples "a model with coverages" do
  it "serializes coverages from the ValueObjects into the JSON column on save" do
    allow(subject).to receive_message_chain("category.coverage_features")
      .and_return([build(:coverage_feature_deckungssumme)])

    subject.coverages = {"deckungssumme" => ValueTypes::Money.new(100.0, "EUR")}
    subject.run_callbacks(:save)

    expect(subject.read_attribute(:coverages))
      .to eq("deckungssumme" => {"value" => 100.00, "currency" => "EUR"})
  end

  context "coverages" do
    context "getters" do
      it "returns an empty hash if the subject has no category" do
        allow(subject).to receive(:category).and_return(nil)

        subject.coverages = {"deckungssumme" => {"value" => 100.00, "currency" => "EUR"}}

        expect(subject.coverages).to eq({})
      end

      it "returns a hash with value objects for all features specified in the category" do
        allow(subject).to receive_message_chain("category.coverage_features")
          .and_return([build(:coverage_feature_deckungssumme)])

        subject.coverages = {"deckungssumme" => {"value" => 100.00, "currency" => "EUR"}}

        expect(subject.coverages["deckungssumme"]).to eq(ValueTypes::Money.new(100, "EUR"))
      end

      it "returns only objects that are allowed in the category" do
        allow(subject).to receive_message_chain("category.coverage_features")
          .and_return([build(:coverage_feature_deckungssumme)])

        subject.coverages = {
          "versicherte_personen" => {"text" => "sometext"},
          "deckungssumme"        => {"value" => 100.00, "currency" => "EUR"}
        }

        expect(subject.coverages["versicherte_personen"]).to be_nil
        expect(subject.coverages["deckungssumme"]).not_to be_nil
      end

      it "can access a single coverage via key" do
        allow(subject).to receive_message_chain("category.coverage_features")
          .and_return([build(:coverage_feature_deckungssumme)])

        subject.coverages = {"deckungssumme" => {"value" => 100.00, "currency" => "EUR"}}

        expect(subject.read_coverage("deckungssumme")).to eq(ValueTypes::Money.new(100, "EUR"))
      end
    end

    context "setters" do
      it "sets only those values that are present in the category" do
        allow(subject).to receive_message_chain("category.coverage_features")
          .and_return([build(:coverage_feature_deckungssumme)])

        subject.coverages = {
          "versicherte_personen" => {"text" => "sometext"},
          "deckungssumme"        => {"value" => 100.00, "currency" => "EUR"}
        }

        coverages = subject.instance_variable_get(:@coverage_details)
        expect(coverages).to have_key("deckungssumme")
        expect(coverages).not_to have_key("versicherte_personen")
      end

      it "transforms the data from hashes to value object types" do
        allow(subject).to receive_message_chain("category.coverage_features")
          .and_return([build(:coverage_feature_deckungssumme)])

        subject.coverages = {
          "versicherte_personen" => {"text" => "sometext"},
          "deckungssumme"        => {"value" => 100.00, "currency" => "EUR"}
        }

        coverages = subject.instance_variable_get(:@coverage_details)

        expect(coverages["deckungssumme"]).to eq(ValueTypes::Money.new(100.0, "EUR"))
      end
    end
  end

  context "formatted_coverages" do
    context "with the correct text" do
      it "returns the correct coverages" do
        allow(subject).to receive_message_chain("category.coverage_features")
          .and_return([build(:coverage_feature_deckungssumme)])

        subject.coverages = {
          "versicherte_personen" => {"text" => "sometext"},
          "deckungssumme" => {"value" => 100.00, "currency" => "EUR"}
        }

        coverages = subject.formatted_coverages

        expect(coverages["Deckungssumme"]).to eq("100,00 €")
      end
    end
  end
end
