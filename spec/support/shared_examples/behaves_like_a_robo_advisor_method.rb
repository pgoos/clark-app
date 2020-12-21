# frozen_string_literal: true

RSpec.shared_examples "a robo advice for method" do |method_name, args={}|
  unless args[:skip_age_check]
    it "does advice product regardless of" do
      product.update!(created_at: 1.second.ago)

      expect do
        subject.send(method_name)
      end.to change { product.interactions.count }.by(2)
    end
  end

  unless args[:skip_updated_advice_check]
    context "product has advice" do
      before do
        subject.send(method_name)
        product.mandate.update!(last_advised_at: 2.days.ago)
      end

      context "new advice differs than old, invalid one" do
        before do
          product.last_advice.update!(
            valid: false,
            content: "outdated advice"
          )
        end

        it "creates new advice" do
          expect { subject.send(method_name) }.to change { product.advices.count }.by(1)
          expect(product.advices.map(&:valid)).not_to include(false)
        end
      end

      context "new advice is same as old, invalid one" do
        before do
          product.last_advice.update!(valid: false)
        end

        it "marks old advice valid" do
          expect { subject.send(method_name) }.to change { product.advices.count }.by(0)
          expect(product.last_advice.valid).to be_truthy
        end
      end
    end
  end

  unless args[:skip_unadviced_check]
    it 'does not advice a product if it was adviced before' do
      Interaction::Advice.create(topic: product, mandate: mandate, content: 'something something', admin: Admin.first)

      expect do
        subject.send(method_name)
      end.not_to change { product.interactions.count }
    end
  end

  unless args[:skip_sold_by_us]
    it 'does not advice a product if it was sold by us' do
      product.update(sold_by: Product::SOLD_BY_US)

      expect do
        subject.send(method_name)
      end.not_to change { product.interactions.count }
    end
  end

  it 'sends the advice from one of the given admins' do
    subject.send(method_name)

    expect(RoboAdvisor::ADVICE_ADMIN_EMAILS).to include(product.interactions.first.admin.email)
  end

  it 'flags the advice as being sent by robo advisory' do
    subject.send(method_name)
    expect(product.advices.first.created_by_robo_advisor).to eq(true)
  end

  unless args[:skip_identifier]
    it "adds the identifier (#{method_name.to_s}) to the advice" do
      subject.send(method_name)

      expected_identifier = args[:custom_identifier] || method_name.to_s
      expect(product.advices.first.identifier).to eq(expected_identifier)
    end
  end

  it "adds the rule_id to the advice" do
    subject.send(method_name)

    expect(product.advices.first.rule_id).not_to be_nil
  end

  it 'flags the push notification as being sent by robo adisory' do
    subject.send(method_name)
    push_notifications = product.interactions.where(type: 'Interaction::PushNotification')

    expect(push_notifications.any?).to be_truthy
    expect(push_notifications.last.created_by_robo_advisor).to eq(true)
  end

  it "sends out an e-mail to the customer" do
    mailer_method = args[:category_ident] == Category.gkv_ident ? :notification_available_gkv : :notification_available
    expect(MandateMailer).to receive(mailer_method).with(Interaction::Advice)
    subject.send(method_name)
  end

  it 'does not advice a product if no e-mail is available' do
    mandate.update_attributes(user: nil)

    expect do
      subject.send(method_name)
    end.not_to change { product.interactions.count }
  end

  it 'does not advice a product if mandate is revoked' do
    mandate.update_attributes(state: 'revoked')

    expect do
      subject.send(method_name)
    end.not_to change { product.interactions.count }
  end
end
