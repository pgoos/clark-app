# frozen_string_literal: true

module Model
  Customer = Struct.new(:first_name,
                        :last_name,
                        :birthdate,
                        :address_line1,
                        :house_number,
                        :place,
                        :zip_code,
                        :email,
                        :password,
                        :phone_number,
                        :mandate_id,
                        :payback_code,
                        :order_number,
                        :source,
                        :invitee_email,
                        :owner_ident,
                        :primary_phone_verified,
                        :accessible_by,
                        :iban)
end
