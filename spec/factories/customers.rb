# frozen_string_literal: true

require Rails.root.join("app", "composites", "customer", "entities", "customer")

# Aggregated customer entity
FactoryBot.define do
  factory :customer, class: "Customer::Entities::Customer" do
    initialize_with do
      mandate

      if registered_with_ip || source_data
        mandate.lead.assign_attributes(
          registered_with_ip: registered_with_ip,
          source_data: source_data
        )
      end

      new(
        id: id,
        mandate_state: mandate_state,
        customer_state: customer_state,
        registered_with_ip: registered_with_ip,
        source_data: source_data,
        birthdate: birthdate,
        email: email,
        password: password
      )
    end

    id { mandate.id || Faker::Number.number(digits: 2) }
    customer_state { mandate.customer_state }
    mandate_state { mandate.state }
    registered_with_ip {}
    source_data {}
    birthdate { mandate.birthdate }
    email {}
    password {}
    mandate {
      build(:mandate, customer_state: "self_service")
    }

    trait :prospect do
      mandate {
        build(:mandate, :with_lead, customer_state: "prospect")
      }

      registered_with_ip { Faker::Internet.ip_v4_address }
      source_data { {} }
    end

    # Using explicitly here build(:mandate, :build_with_user) because of we have a flaky issue,
    # from time to time it creates a mandate WITHOUT user with this expression -
    # association :mandate,
    #          factory: %i[mandate with_user],
    #          strategy: :build

    trait :self_service do
      mandate {
        build(:mandate,
              :build_with_user,
              customer_state: "self_service",
              phone: ClarkFaker::PhoneNumber.cell_phone,
              password: password || Settings.seeds.default_password)
      }

      registered_with_ip {}
      source_data {}
    end

    trait :mandate_customer do
      mandate {
        build(:mandate,
              :build_with_user,
              customer_state: "mandate_customer",
              phone: ClarkFaker::PhoneNumber.cell_phone,
              password: password || Settings.seeds.default_password)
      }

      registered_with_ip {}
      source_data {}
    end

    trait :unapproved_mandate_customer do
      mandate do
        build(
          :mandate,
          :build_with_user,
          customer_state: "mandate_customer",
          state: "created",
          phone: ClarkFaker::PhoneNumber.cell_phone,
          info: { wizard_steps: %w[targeting profiling confirming] },
          password: password || Settings.seeds.default_password,
          confirmed_at: DateTime.current,
          tos_accepted_at: DateTime.current,
          wizard_disabled: true
        )
      end

      registered_with_ip { }
      source_data { }
    end

    before(:create) do |customer, obj|
      # When using create Strategy that will call save! method in defined object and
      # as this is just a PORO then save! doesn't make sense
      customer.define_singleton_method(:save!) {
        [obj.mandate.lead, obj.mandate.user].each do |emailable|
          next unless emailable
          meaningful_domain = "#{obj.mandate.customer_state.gsub('_', '-')}.clark.de"
          emailable.email = "#{emailable.email.split('@')[0]}@#{meaningful_domain}"
          emailable.email = obj.email if obj.email
          emailable.save!
        end

        obj.mandate.birthdate = obj.birthdate if obj.birthdate

        obj.mandate.save!
        phone = obj.mandate.phones.first
        if phone.present?
          phone.verified_at = Time.zone.now
          phone.save!
        end
        obj.mandate.lead&.save!
        @attributes[:id] = obj.mandate.id
      }
    end

    # rubocop:disable Style/EvalWithLocation
    after(:create) do |customer|
      customer.instance_eval("undef :save!")
    end
    # rubocop:enable Style/EvalWithLocation
  end
end
