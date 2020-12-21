# frozen_string_literal: true

RSpec.shared_examples "checks mail rendering" do
  let(:html_part) { "bodyCell" }

  it "renders the email successfully" do
    expect(mail.body.encoded).to include(html_part)
  end
end

RSpec.shared_examples "tracks document and mandate in ahoy email" do
  it "tracks document and mandate in ahoy email" do
    expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(1)
    expect_document_tracked_in_ahoy_emails(
      documentable,
      document_type,
      mandate
    )
  end
end

RSpec.shared_examples "does not track email in ahoy" do
  it "does not track email in ahoy" do
    expect { mail.deliver_now }.not_to change { Ahoy::Message.count }
    expect(mail.body.encoded).not_to match(/http:\/\/test.host\/ahoy\/messages\/\w{32}\/open.gif/)
    expect(mail.body.encoded).not_to match(/ahoy\/messages/)
  end
end

RSpec.shared_examples "does not send out an email if mandate belongs to the partner" do
  it "does not send out an email if mandate belongs to the partner" do
    mandate.owner_ident = "test_partner_ident"
    mail.deliver_now
    expect(ActionMailer::Base.deliveries.count).to eq(0)
    ActionMailer::Base.deliveries.clear
  end
end

RSpec.shared_examples "send out an email if mandate belongs to the partner" do
  it "sends out an email if mandate belongs to the partner" do
    mandate.owner_ident = "test_partner_ident"
    mail.deliver_now
    expect(ActionMailer::Base.deliveries.count).to eq(1)
    ActionMailer::Base.deliveries.clear
  end
end

RSpec.shared_examples "sends out an email when user is subscriber" do
  it "sends out an email if mandate belongs to the partner" do
    user = mandate.user
    user.subscriber = false
    mail.deliver_now
    expect(ActionMailer::Base.deliveries.count).to eq(1)
    ActionMailer::Base.deliveries.clear
  end
end

RSpec.shared_examples "stores a message object upon delivery" do |mailer_name, utm_source, campaing_name|
  it "stores a message object upon delivery" do
    expect { mail.deliver_now }.to change { Ahoy::Message.count }.by(1)

    message = Ahoy::Message.last
    expect(message.to).to eq(email)
    expect(message.token).to match(/\w{32}/)

    expect(message.mailer).to eq(mailer_name)

    expect(message.utm_medium).to eq("email")
    expect(message.utm_source).to eq(utm_source)
    expect(message.utm_campaign).to eq(campaing_name)
  end
end
