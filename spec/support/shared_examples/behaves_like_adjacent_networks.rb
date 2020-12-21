# frozen_string_literal: true

RSpec.shared_examples "adjacent networks" do |networks|
  min_ip_addr = IPAddr.new(networks.first)
  max_ip_addr = IPAddr.new(networks.last)
  minimum_ip = min_ip_addr.to_range.first
  maximum_ip = max_ip_addr.to_range.last

  minimum = minimum_ip.to_s
  maximum = maximum_ip.to_s
  lower, above = if min_ip_addr.ipv6?
                   [
                     (min_ip_addr << 1).to_s,
                     (max_ip_addr >> 1).to_s
                   ]
                 else
                   [
                     IPAddr.new(minimum_ip.to_i - 1, Socket::AF_INET).to_s,
                     IPAddr.new(maximum_ip.to_i + 1, Socket::AF_INET).to_s
                   ]
                 end

  context networks.join(", ") do
    it "should not work for one lower of the minimum adjust ip #{lower}" do
      request.headers["REMOTE_ADDR"] = lower
      get :event, params: {locale: "de", activity_kind: "click", event_time: Time.new.to_i}
      expect(response.status).to eq(403)
    end

    it "should work for the minimum ajust ip #{minimum}" do
      request.headers["REMOTE_ADDR"] = minimum
      get :event, params: {locale: "de", activity_kind: "click", event_time: Time.new.to_i}
      expect(response.status).to eq(204)
    end

    it "should work for the maximum ajust ip #{maximum}" do
      request.headers["REMOTE_ADDR"] = maximum
      get :event, params: {locale: "de", activity_kind: "click", event_time: Time.new.to_i}
      expect(response.status).to eq(204)
    end

    it "should not work for one above of the maximum adjust ip #{above}" do
      request.headers["REMOTE_ADDR"] = above
      get :event, params: {locale: "de", activity_kind: "click", event_time: Time.new.to_i}
      expect(response.status).to eq(403)
    end
  end
end
