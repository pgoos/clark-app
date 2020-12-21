# frozen_string_literal: true

RSpec.shared_examples "robo classifiable" do
  it "expose classifications" do
    expect(subject).to respond_to(:classifications)
  end

  context "#current_classification" do
    it "allow adding classes" do
      subject.add_classification(:switcher)

      expect(subject.classifications).to eq([:switcher])
    end

    it "allow adding many classes" do
      subject.add_classification(:switcher)
      subject.add_classification(:keeper)

      expect(subject.classifications).to eq(%i[switcher keeper])
    end

    it "does not double classifications" do
      subject.add_classification(:switcher)
      subject.add_classification(:switcher)
      expect(subject.classifications.length).to eq(1)
    end

    it "does not add a nil classification" do
      subject.add_classification(nil)
      expect(subject.classifications.length).to eq(0)
    end
  end

  context "#current_classification" do
    it "is classified as the last class" do
      subject.add_classification(:switcher)
      subject.add_classification(:keeper)

      expect(subject.current_classification).to eq(:keeper)
    end
  end
end
