# frozen_string_literal: true

RSpec.shared_examples "an identifiable for name model" do
  # Company -> :company
  let(:factory_name) { described_class.class_name.downcase.to_sym }

  context "when a record is new" do
    let(:model) { build(factory_name, ident: nil, name: "A fine name") }
    let(:prefix) { "afine" }

    it "generates an ident" do
      model.save!
      expect(model.ident).to be_present
      expect(model.ident).to start_with(prefix)
    end
  end

  context "when the ident is already set" do
    let(:model) { create(factory_name, name: "A fine name") }
    let(:ident) { model.ident }

    it "does not change the ident" do
      model.update!(name: "New name")

      expect(model.ident).to eq(ident)
      expect(model.name).to eq("New name")
    end
  end

  context "when the name is repeated" do
    let(:name) { "A fine name" }
    let!(:model1) { create(factory_name, name: "A fine name") }
    let!(:model2) { create(factory_name, name: "A fine name") }

    it "generates new ident" do
      expect(model1.ident).not_to eq model2.ident
    end
  end

  context "when name is repeated a lot of times" do
    let(:name) { "A fine name" }
    let(:prefix) { "afine" }
    let(:abbreviation) { ident }

    it "raises an exception" do
      expect { 11.times.each { create(factory_name, name: name) } } \
        .to raise_error("Not enough idents for #{prefix} and #{name}")
    end
  end
end
