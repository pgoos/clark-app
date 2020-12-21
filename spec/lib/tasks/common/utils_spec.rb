# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../lib/tasks/common/utils"

describe ::Tasks::Common::Utils do
  let(:logger) { double(info: "") }

  describe ".with_logging" do
    it do
      expect { |block| described_class.with_logging(logger, &block) }.to yield_control
    end
  end
end
