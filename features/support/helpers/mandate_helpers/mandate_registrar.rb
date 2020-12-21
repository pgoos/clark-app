# frozen_string_literal: true

module Helpers
  module MandateHelpers
    module MandateRegistrar
      # TODO: add logging [JCLARK-57847]
      def register_mandate(customer, inquiries=nil)
        inquiries         = default_inquiries if inquiries.nil?
        mandate_registrar = MandateRegistrar.new(customer, inquiries)
        mandate_registrar.register_mandate
      end

      class MandateRegistrar
        def initialize(customer, inquiries)
          @customer   = customer
          @inquiries  = inquiries
          @api_facade = ApiFacade.new
        end

        def register_mandate
          init_mandate_funnel
          phone_verification
          targeting
          profiling
          confirming
          finish_registration
        end

        private

        def init_mandate_funnel
          @api_facade.web_app.get_sign_up_cookies
          @api_facade.v2.get_csrf_token
          @api_facade.v2.get_current_user
        end

        def phone_verification
          @api_facade.v2.post_phone_number_for_ver(@customer.phone_number)
          token = TestContextManager.instance.sms_service.get_verification_token(@customer.phone_number)
          @api_facade.v2.post_phone_number_ver_code(token)
        end

        def targeting
          companies  = @api_facade.v2.get_companies
          categories = @api_facade.v4.get_active_categories
          @api_facade.v2.add_inquiries(@inquiries, companies, categories)
          @api_facade.v2.complete_targeting_step
        end

        def profiling
          @api_facade.v2.get_current_user
          @api_facade.v2.update_email(@customer.email)
          @api_facade.v2.update_profile(@customer)
          @api_facade.v2.complete_profiling_step
        end

        def confirming
          @api_facade.automation_helpers.post_create_signature_for_mandate
          @api_facade.v2.complete_confirming_step
        end

        def finish_registration
          @api_facade.v2.post_register(@customer.password)
          @customer.mandate_id = @api_facade.session.current_user_mandate_id
        end
      end

      private_constant :MandateRegistrar
    end
  end
end
