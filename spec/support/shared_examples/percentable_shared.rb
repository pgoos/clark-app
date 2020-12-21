RSpec.shared_examples 'a percentable model' do
  it { expect(described_class).to respond_to(:percentage) }  
end

#
# Plugins
# ---------------------------------------------------------------------------------------
#
#
#
#

RSpec.shared_examples "a model with percentage attributes" do |*attributes|
  attributes.each do |attr|
    let(:model) { build ActiveModel::Naming.singular(described_class) }
  
    it 'enforce convention: percentage attributes are postfixed with "percent"' do
      expect(attr.to_s.split('_').last).to eq 'percent'
    end
  
    it 'is used only if concern percentable is included' do
      expect(described_class.include?(Percentable)).to be true
    end
  
    it { expect(model).to respond_to("#{attr}_before_type_cast") }
    it { expect(model).to respond_to("#{attr}") }
    it { expect(model).to respond_to("#{attr}=") }
    it { expect(model).to respond_to("#{attr}_multiplier") }
    it { expect(model).to respond_to("#{attr}_multiplier=") }
  
    describe "#{attr}=" do
      before { model.send("#{attr}=", 10) }
    
      it { expect(model.instance_variable_get("@#{attr}")).to eq(BigDecimal.new("0.1")) }
      it { expect(model.read_attribute(attr)).to eq(BigDecimal.new("0.1")) }
    end
  
    describe "#{attr}" do
      subject { model.send("#{attr}") }

      context "when ActiveRecord attribute #{attr} is set" do
        before { model.send(:write_attribute, attr, BigDecimal.new("0.1")) }

        it { is_expected.to eq 10 }
      end
    
      context "when #{described_class} responds to fetch_attributes" do
        pending 'add tests for the "fetch_attribute" case'
      end
    
    end
  
    describe "#{attr}_multiplier=" do
      before { model.send("#{attr}_multiplier=", 0.1) }
    
      it { expect(model.read_attribute(attr)).to eq(BigDecimal.new("0.1")) }
    end
  
    describe "#{attr}_multiplier" do
      subject { model.send("#{attr}_multiplier") }
    
      context "when ActiveRecord attribute #{attr} is set" do
        before { model.send(:write_attribute, attr, BigDecimal.new("0.1")) }

        it { is_expected.to eq 0.1 }
      end
    
      context "when #{described_class} responds to fetch_attributes" do
        pending 'add tests for the "fetch_attribute" case'
      end
    end
  
    describe "#{attr}_before_type_cast" do
      subject { model.send("#{attr}_before_type_cast") }

      context "when @#{attr} is set" do
        before { model.instance_variable_set("@#{attr}", BigDecimal.new("0.1")) }

        it { is_expected.to eq 10 }
      end

      context "when ActiveRecord attribute #{attr} is set" do
        before { model.send("#{attr}=", 10) }

        it { is_expected.to eq 10 }
      end
    end
  end
end