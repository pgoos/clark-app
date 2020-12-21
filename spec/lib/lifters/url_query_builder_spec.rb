# frozen_string_literal: true

require 'url_query_builder'

require "rails_helper"

RSpec.describe UrlQueryBuilder do

  let(:empty_params) { UrlQueryBuilder.new([]) }

  it 'takes the query params in the init function and turns it into a query string' do
    builder = UrlQueryBuilder.new(['key', 'value'])
    expect(builder.to_query).to match(/^key=value$/)
  end

  it 'takes the query params in the init function and in the param function' do
    builder = UrlQueryBuilder.new(['key', 'value'])
    builder.param('hello', 'world')
    expect(builder.to_query).to match(/^key=value&hello=world$/)
  end

  it 'takes the query params separately' do
    builder = UrlQueryBuilder.new
    builder.param('key','value').param('hello', 'world')
    expect(builder.to_query).to match(/^key=value&hello=world$/)
  end
end
