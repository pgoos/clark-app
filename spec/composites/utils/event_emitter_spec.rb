# frozen_string_literal: true

require "rails_helper"
require "composites/utils/event_emitter"

RSpec.describe Utils::EventEmitter do
  # rubocop:disable RSpec/LeakyConstantDeclaration
  module Example
    module Container
      extend Dry::Container::Mixin
      extend Utils::EventEmitter::ContainerMixin
    end
  end
  # rubocop:enable RSpec/LeakyConstantDeclaration

  it "register emitter  in container" do
    expect(Example::Container.resolve(:emit_event)).to be_kind_of(Utils::EventEmitter::Emit)
  end

  it "sets up emitter to use composite namespace" do
    emitter = Example::Container.resolve(:emit_event)
    expect(emitter.instance_variable_get(:"@namespace")).to eq "example"
  end
end
