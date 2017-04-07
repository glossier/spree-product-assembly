module Spree
  OrderContents.class_eval do

    def add_to_line_item(variant, quantity, options = {})
      line_item = grab_line_item_by_variant(variant, false, options)

      if line_item && part_variants_match?(line_item, variant, quantity, options)
        line_item
      else
        line_item = order.line_items.new(
          quantity: 0,
          variant: variant,
          currency: order.currency
        )
      end

      line_item.quantity += quantity.to_i
      line_item.options = ActionController::Parameters.new(options).permit(PermittedAttributes.line_item_attributes)

      if line_item.new_record?
        create_order_stock_locations(line_item, options[:stock_location_quantities])
      end

      line_item.target_shipment = options[:shipment]
      line_item.save!
      line_item
    end

    def add_to_line_item_with_parts(variant, quantity, options = {})
      add_to_line_item_without_parts(variant, quantity, options).
        tap do |line_item|
        populate_part_line_items(
          line_item,
          variant.parts_variants,
          options[:selected_variants]
        )
      end
    end

    alias_method_chain :add_to_line_item, :parts

    private

    def part_variants_match?(line_item, variant, quantity, options)
      if line_item.parts.any? && options[:selected_variants]
        selected_variant_ids = options[:selected_variants].map(&:to_i)
        matched = part_variant_ids(line_item) & selected_variant_ids

        matched == selected_variant_ids
      else
        true
      end
    end

    def part_variant_ids(line_item)
      line_item.part_line_items.map(&:variant_id)
    end

    def populate_part_line_items(line_item, parts, selected_variants)
      return if parts.nil?
      if selected_variants.nil?
        parts.each do |part|
          part_line_item = line_item.part_line_items.find_or_initialize_by(
            line_item: line_item,
            variant_id: variant_id_for(part, selected_variants)
          )

          part_line_item.update_attributes!(quantity: part.count)
        end
      else
        selected_variants.each do |variant|
          part_line_item = line_item.part_line_items.find_or_initialize_by(
            line_item: line_item,
            variant_id: variant
          )

          part_line_item.update_attributes!(quantity: 1)
        end
        add_mandatory_parts(parts, line_item)
      end
    end
    
    def add_mandatory_parts(parts, line_item)
      parts.where('variant_selection_deferred IS NULL').each do |part|
        part_line_item = line_item.part_line_items.find_or_initialize_by(
          line_item: line_item,
          variant_id: variant_id_for(part, nil)
        )

        part_line_item.update_attributes!(quantity: part.count)
      end
    end

    def variant_id_for(part, selected_variants)
      if part.variant_selection_deferred?
        selected_variants[part.part.id.to_s]
      else
        part.part.id
      end
    end
  end
end
