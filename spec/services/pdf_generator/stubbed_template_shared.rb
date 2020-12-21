# frozen_string_literal: true

RSpec.shared_context "stubbed template" do
  def stub_template(template, contents)
    described_class.view_instance.view_paths.unshift(
      ActionView::FixtureResolver.new(template => contents)
    )
  end

  let(:template) { "pdf_generator/pdf_template" }
  let(:locals) { {local_variable: "variable_value"} }

  before { stub_template("#{template}.html.haml", "%p Hello world \n%p= local_variable") }
end
