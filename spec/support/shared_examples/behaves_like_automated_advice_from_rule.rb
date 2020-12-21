RSpec.shared_examples "automated_advice_from_rule" do
  let(:subject) { Sales::Rules::GkvAdviceRule.new(product: product) }
  let(:premium_method) { :national_health_insurance_premium_percentage }

  before do
    allow(product).to receive(premium_method).and_return(premium)
    allow(product).to receive_message_chain(:company, :ident).and_return(company_ident)
    allow(product).to receive_message_chain(:company, :gkv_whitelisted?).and_return(true)
  end

  it "should create tkk advice" do
    expect(Sales::Advices::GkvAdviceFactory).to receive(advice_type).with(product)
    subject.on_application { |advice| }
  end

  it "should yield the advice to the given block" do
    expected_advice = double(Interaction::Advice)
    allow(Sales::Advices::GkvAdviceFactory).to receive(advice_type)
                                               .with(product).and_return(expected_advice)

    actual_advice = nil
    subject.on_application { |advice| actual_advice = advice }

    expect(actual_advice).to eq(expected_advice)
  end
end
