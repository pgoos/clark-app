# frozen_string_literal: true

require_relative "../../page.rb"

class NewOfferPage
  include Page

    def set_value(offer_option_number, param_name, param_value)
      map_fields if @fields_map.nil?
      node = find("#offer_offer_options_attributes_#{offer_option_number}_#{@fields_map[param_name]}")
      case node.tag_name
      when "input"
        node.set(param_value)
      when "select"
        node.find(:option, param_value).select_option
      else
        raise NotImplementedError.new
      end
    end

    def mark_recommended(offer_option_number)
      set_value(offer_option_number, "Empfohlen", true)
    end

    def add_param_to_offer_view(param_name)
      find(:xpath, "//label[contains(@title,'#{param_name}')]").find("input.feature-check").set(true)
    end

    def enter_message_for_customer(message)
      find("#offer_note_to_customer").set(message)
    end

    private

    def map_fields
      # first 8 options are static and the same for each product type. Other options can be mapped dynamically
      # noinspection RubyStringKeysInHashInspection
      @fields_map = {"Verkaufsargument" => "option_type",
                     "Empfohlen" => "recommended",
                     "Gruppe" => "product_attributes_company_id",
                     "Gesellschaft" => "product_attributes_subcompany_id",
                     "Tarif" => "product_attributes_plan_id_chosen",
                     "Prämie" => "product_attributes_premium_price",
                     "Zahlungsrythmus" => "product_attributes_premium_period",
                     "Vertragsbeginn" => "product_attributes_contract_started_at",
                     "Vertragsende" => "product_attributes_contract_ended_at"}

      # This part is currently not in use for the required fields to generate an offer.
      # In future if we add new fields we can fix this piece of code.
      # Currently it's just failing our test because
      # line 54 is returning nil,Commenting increases value of having green test

      # labels = find("div.offer-option-box.offer-option-labels").all("label.col-form-label")
      #  labels[9..-1].each do |label|
      #   @fields_map[label.text] = "product_attributes_coverages_#{label.find('input')['value']}_value"
      # end
    end
end
