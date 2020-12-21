# frozen_string_literal: true

module DoubleHelpers
  def n_double(name, **args)
    double(build_name(name), args)
  end

  def n_instance_double(klazz, name, **args)
    instance_double(klazz, build_name(name), args)
  end

  private

  def build_name(name)
    "spec(#{described_class.name})▬▶#{name}"
  end
end
