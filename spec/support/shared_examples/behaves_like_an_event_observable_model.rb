# frozen_string_literal: true

RSpec.shared_examples "an event observable model" do
  it "should be a model" do
    expect(subject).to be_an(ActiveRecord::Base)
  end

  it "should be an observable in order to broadcast events" do
    expect(subject).to be_an(EventObservable)
  end

  context "model lifecycle events" do
    subject { FactoryBot.build(ActiveModel::Naming.singular(described_class)) }

    let(:listener_spy) do
      mock_listener_clazz = Class.new do
        def initialize(model_clazz)
          @model_clazz = model_clazz
          @calls = {
            after_create:   0,
            after_update:   0,
            after_destroy:  0,
            after_commit:   0,
            after_rollback: 0
          }.with_indifferent_access
        end

        def calls_for(callback)
          @calls[callback]
        end

        def after_create(instance)
          increment_calls(:after_create, instance)
        end

        def after_update(instance)
          increment_calls(:after_update, instance)
        end

        def after_destroy(instance)
          increment_calls(:after_destroy, instance)
        end

        def after_commit(instance)
          increment_calls(:after_commit, instance)
        end

        def after_rollback(instance)
          increment_calls(:after_rollback, instance)
        end

        private

        def increment_calls(callback_name, instance)
          raise "#{instance} is not a #{@model_clazz}!" unless instance.is_a?(@model_clazz)
          @calls[callback_name] += 1
        end
      end

      mock_listener_clazz.new(described_class)
    end

    it "should send the after_create event" do
      subject.subscribe(listener_spy)
      subject.save!
      expect(listener_spy.calls_for(:after_create)).to eq(1)
    end

    context "invalid object" do
      let(:subject) { described_class.new }

      it "should send the after_rollback event" do
        subject.subscribe(listener_spy)
        subject.save
        expect(subject).not_to be_persisted
        expect(listener_spy.calls_for(:after_rollback)).to eq(1)
      end

      it "should not send the after_create event, if the creation failed" do
        subject.subscribe(listener_spy)
        subject.save
        expect(listener_spy.calls_for(:after_create)).to eq(0)
      end
    end

    context "saved" do
      before do
        subject.subscribe(listener_spy)
        subject.save!
      end

      it "should send the after_update event" do
        subject.save!
        expect(listener_spy.calls_for(:after_update)).to eq(1)
      end

      it "should send the after_destroy event" do
        subject.destroy!
        expect(listener_spy.calls_for(:after_destroy)).to eq(1)
      end

      it "should send the after_commit event" do
        expect(listener_spy.calls_for(:after_commit)).to eq(1)
      end
    end

    #
    # Not covered by regression specs:
    # ================================
    #
    # create_<model_name>_{successful, failed}
    # update_<model_name>_{successful, failed}
    # destroy_<model_name>_successful
    # <model_name>_committed
    #

  end
end
