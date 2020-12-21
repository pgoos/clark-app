# frozen_string_literal: true

RSpec.shared_context "event fixtures" do
  let(:local_product_id) { (rand * 100).round }
  let(:remote_product_id) { (rand * 100).round + 100 }
  let(:product) do
    instance_double(
      Product,
      id:             local_product_id,
      qualitypool_id: remote_product_id
    )
  end

  let(:service_double) { instance_double(Qualitypool::BasicRPCService) }
  let(:payload) { example_payload(0) }
  let(:response) { example_response(remote_product_id, 1) }

  let(:mailer_double) { instance_double(OutboundChannels::Mailer) }
  let(:mail_from) { "service@test.clark.de" }
  let(:mail_to) { "qualitypool@test.clark.de" }

  before do
    allow(Settings).to receive_message_chain(:emails, :return_path).and_return(mail_from)
    allow(Settings).to receive_message_chain(:qualitypool, :ops_mail_to).and_return(mail_to)
    allow(Settings).to receive_message_chain(:emails, :service).and_return("test<service@clark.de>")
  end

  def payload_and_response_with_later_ids(payload, response, override_previous_id=nil)
    previous_id                  = override_previous_id || (rand * 100).round + 10
    payload[:EreignisID]         = previous_id
    new_id                       = previous_id + 1
    response.result[:EreignisID] = new_id
    remote_next = Qualitypool::PullEventService::REMOTE_METHOD_NEXT_EVENT
    allow(service_double).to receive(:execute_rpc_call).with(remote_next, payload)
      .and_return(response)
    [previous_id, new_id]
  end

  def example_payload(previous_event_id)
    {
      "EreignisID": previous_event_id
    }
  end

  def example_response(vertrag_id, event_id)
    data = {
      "jsonrpc": "2.0",
      "id":      "21f81cc7-08ae-7be1-769a-f9a0c11cad61",
      "result":  {
        "EreignisID":       event_id,
        "Zeitstempel":      "2019-01-01T00:00:00",
        "Geschaeftsvorgang": "sample business transaction name",
        "Fachobjekte":      {"VertragID": vertrag_id},
        "Vertrag":          {}
      }
    }
    Ripcord::JsonRPC::Response.from_data(data)
  end
end
