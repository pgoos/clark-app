# frozen_string_literal: true

RSpec.shared_context "silenced robo advisor notifications" do
  before do
    # We generally do not care about mails or pushes being sent out. We check specifically where needed
    allow(MandateMailer).to receive_message_chain('notification_available.deliver_now')
    allow(PushService).to receive(:send_push_notification).with(mandate, any_args())
                            .and_return([double(Device, human_name: 'some iPhone')])
  end
end
