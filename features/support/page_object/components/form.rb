# frozen_string_literal: true

module Components
  # This component provides methods to operate with forms
  module Form
    # Method fills out form with provided values
    # Custom method should be implemented. Example: def fill_out_address_edit_form(value) { }
    # @param hashes [Array<Hash>] hashes of values to be send
    # @param marker [String] custom method marker || form name
    def fill_out_form(marker, hashes)
      # dispatch
      custom_method = "fill_out_#{marker.tr(' ', '_')}_form"
      if respond_to?(custom_method, true)
        hashes.each do |form_attributes|
          send(custom_method, form_attributes)
          sleep 0.5
        end
        return
      end
      # TODO: Implement default method for forms
      raise NotImplementedError "No method implemented for #{marker} form"
    end
  end
end
