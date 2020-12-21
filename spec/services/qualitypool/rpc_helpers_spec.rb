require 'rails_helper'

RSpec.describe Qualitypool::RpcHelpers do

  subject do
    class DummyRpcHelpersClass
      include Qualitypool::RpcHelpers
    end.new
  end

  let(:key_to_nil) { "key_to_nil_#{rand}" }
  let(:key_to_sth) { "key_to_sth_#{rand}" }

  context "#compact_hash_tree" do
    it "should remove dangling keys on the first level" do
      hash = { key_to_sth => 1, key_to_nil => nil}
      compacted_hash = subject.compact_hash_tree(hash)
      expect(compacted_hash.has_key?(key_to_nil)).to be(false)
    end

    it "should remove dangling keys on the second level" do
      hash = { key_to_sth => { key_to_nil => nil, "key3" => 3}}
      compacted_hash = subject.compact_hash_tree(hash)
      expect(compacted_hash[key_to_sth].has_key?(key_to_nil)).to be(false)
    end

    it "should compact nested arrays" do
      hash = { key_to_sth => [nil, 3]}
      compacted_hash = subject.compact_hash_tree(hash)
      expect(compacted_hash[key_to_sth]).to match_array([3])
    end
  end
end
