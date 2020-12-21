require 'rails_helper'

#TODO: Also something that is not well designed
RSpec.describe Platform::RuleEngineV3::Concerns::Traceable do
  let(:subject) do
    class TrackableClass
      include Platform::RuleEngineV3::Concerns::Traceable
    end
    TrackableClass.new
  end

  let(:ok_payload) { {status: 'OK', ident: 'rule'} }
  let(:error_payload) { {status: 'ERROR', ident: 'rule'} }

  before { allow_any_instance_of(Admin).to receive(:refresh_permissions) }
  
  context '#trace_run' do
    let(:product_model) { create(:product) }
    let!(:admin) { create(:super_admin) }

    it 'throws an error without mode' do
      expect{
        subject.trace_run(nil, ok_payload)
      }.to raise_exception(ArgumentError)
    end

    it 'throws an error without an identifier' do
      expect{
        subject.trace_run(product_model, {status: 'OK'})
      }.to raise_exception(ArgumentError)
    end

    it 'throws an error without status' do
      expect{
        subject.trace_run(product_model, {ident: 'rule'})
      }.to raise_exception(ArgumentError)
    end

    it 'throws an error if model does not have a mandate' do
      product_model.update_attributes(mandate: nil)

      expect{
        subject.trace_run(product_model, ok_payload)
      }.to raise_exception(ArgumentError)
    end

    it 'has clarkbot as auditable person' do
      subject.trace_run(product_model, ok_payload)
      expect(BusinessEvent.last.person).to eq(Admin.first)
    end

    it 'has action automation_run' do
      subject.trace_run(product_model, ok_payload)
      expect(BusinessEvent.last.action).to eq('automation_run')
    end

    it 'has model as entity' do
      subject.trace_run(product_model, ok_payload)
      expect(BusinessEvent.last.entity).to eq(product_model)
    end

    it 'has audited_mandate as the model mandate' do
      subject.trace_run(product_model, ok_payload)
      expect(BusinessEvent.last.audited_mandate).to eq(product_model.mandate)
    end

    it 'has metadata as the passed metadata' do
      subject.trace_run(product_model, error_payload)
      expect(BusinessEvent.last.metadata).to eq({'status' => 'ERROR', 'ident' => 'rule'})
    end

    it 'allows for override the mandate' do
      mandate = create(:mandate)
      product_model.update_attributes(mandate: nil)
      subject.trace_run(product_model, error_payload, mandate)
      expect(BusinessEvent.last.audited_mandate).to eq(mandate)
    end

    it 'must have a model mandate or an overriden mandate' do
      expect{
        subject.trace_run(double(), ok_payload)
      }.to raise_exception(ArgumentError)
    end
  end

  context '#trace_result' do
    let(:product_model) { create(:product) }
    let!(:admin) { create(:super_admin) }

    it 'throws an error without model' do
      expect{
        subject.trace_result(nil, ok_payload)
      }.to raise_exception(ArgumentError)
    end

    it 'throws an error without status' do
      allow(product_model).to receive(:mandate).and_return(product_model)

      expect{
        subject.trace_result(product_model, {})
      }.to raise_exception(ArgumentError)
    end

    it 'throws an error without an identifier' do
      expect{
        subject.trace_result(product_model, {status: 'OK'})
      }.to raise_exception(ArgumentError)
    end

    it 'throws an error if model does not have a mandate' do
      product_model.update_attributes(mandate: nil)

      expect{
        subject.trace_result(product_model, {status: 'OK'})
      }.to raise_exception(ArgumentError)
    end

    it 'has clarkbot as auditable person' do
      subject.trace_result(product_model, ok_payload)
      expect(BusinessEvent.last.person).to eq(Admin.first)
    end

    it 'has action automation_run' do
      subject.trace_result(product_model, ok_payload)
      expect(BusinessEvent.last.action).to eq('automation_result')
    end

    it 'has model as entity' do
      subject.trace_result(product_model, ok_payload)
      expect(BusinessEvent.last.entity).to eq(product_model)
    end

    it 'has audited_mandate as the model mandate' do
      subject.trace_result(product_model, ok_payload)
      expect(BusinessEvent.last.audited_mandate).to eq(product_model.mandate)
    end

    it 'has metadata as the passed metadata' do
      subject.trace_result(product_model, error_payload)
      expect(BusinessEvent.last.metadata).to eq({'status' => 'ERROR', 'ident' => 'rule'})
    end

    it 'allows for override the mandate' do
      mandate = create(:mandate)
      product_model.update_attributes(mandate: nil)
      subject.trace_result(product_model, error_payload, mandate)
      expect(BusinessEvent.last.audited_mandate).to eq(mandate)
    end

    it 'must have a model mandate or an overriden mandate' do
      expect{
        subject.trace_result(double(), ok_payload)
      }.to raise_exception(ArgumentError)
    end
  end
end
