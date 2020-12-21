# frozen_string_literal: true

require "spec_helper"

require "composites/interactors/result"

class DummyClass
  def call(value: 100)
    value
  end
end

RSpec.describe Interactors::Result do
  let(:value) { 10 }
  let(:exception) { StandardError.new("error!") }

  describe described_class::Okay do
    let(:okay) { described_class.new(value) }

    describe "#ok?" do
      it "returns true" do
        expect(okay.ok?).to be true
      end
    end

    describe "#error?" do
      it "returns false" do
        expect(okay.error?).to be false
      end
    end

    describe "#on_success" do
      it "yields the given block passing current value" do
        expect { |block| okay.on_success(&block) }.to yield_with_args(value)
      end
    end

    describe "#on_failure" do
      it "does not yield" do
        expect { |block| okay.on_failure(&block) }.not_to yield_control
      end
    end

    describe "#on" do
      it "does not yield" do
        expect { |block| okay.on(StandardError, &block) }.not_to yield_control
      end
    end

    describe "#and_then" do
      it "yields the given block passing current value" do
        okay.and_then do |value|
          expect(value).to be(value)
          described_class.new(10)
        end
      end

      it "yields the given block and return a new result" do
        new_okay = okay.and_then { |value| described_class.new(value * value) }
        expect(new_okay).not_to be(okay)
        new_okay.on_success { |value| expect(value).to be(100) }
      end

      it "raises a TypeError exception" do
        expect {
          okay.and_then { |value| value * value }
        }.to raise_error(TypeError, "block did not return Result::Base instance")
      end
    end

    describe "#or_else" do
      it "does not yield the given block" do
        expect { |block| okay.or_else(&block) }.not_to yield_control
      end
    end
  end

  describe described_class::Error do
    let(:error) { described_class.new(exception) }

    describe "#ok?" do
      it "returns false" do
        expect(error.ok?).to be false
      end
    end

    describe "#error?" do
      it "returns true" do
        expect(error.error?).to be true
      end
    end

    describe "#on_success" do
      it "does not yield" do
        expect { |block| error.on_success(&block) }.not_to yield_control
      end
    end

    describe "#on_failure" do
      it "yields the given block passing current error value" do
        expect { |block| error.on_failure(&block) }.to yield_with_args(exception)
      end
    end

    describe "#on" do
      context "when the error is the type that was passed" do
        it "yields the given block passing current error" do
          expect { |block| error.on(StandardError, &block) }.to yield_with_args(exception)
        end
      end

      context "when the error is not the type that was passed" do
        it "does not yield the given block" do
          expect { |block| error.on(ArgumentError, &block) }.not_to yield_control
        end
      end
    end

    describe "#and_then" do
      it "does not yield the given block" do
        expect { |block| error.and_then(&block) }.not_to yield_control
      end
    end

    describe "#or_else" do
      it "yields the given block passing current error value" do
        error.or_else do |ex|
          expect(ex).to be(exception)
          described_class.new(exception)
        end
      end

      it "yields the given block and return a new result" do
        new_result = error.or_else { Interactors::Result::Okay.new(2 * 2) }
        expect(new_result).not_to be(error)
        new_result.on_success { |value| expect(value).to be(4) }
      end

      it "raises a TypeError exception" do
        expect {
          error.or_else { "Something" }
        }.to raise_error(TypeError, "block did not return Result::Base instance")
      end
    end
  end

  describe "Utilities" do
    describe "include" do
      context "when class do not include #{described_class}" do
        it "does not return a Result::Base" do
          dc = DummyClass.new

          expect(dc.call).not_to be_kind_of described_class::Base
        end
      end

      context "when class includes #{described_class}" do
        before do
          DummyClass.include(described_class)
        end

        it "returns a Result::Base" do
          dc = DummyClass.new

          expect(dc.call).to be_kind_of described_class::Base
        end

        it "adds multi_return method to its methods set" do
          dc = DummyClass.new

          expect(dc.respond_to?(:multi_return)).to be true
        end
      end
    end
  end
end
