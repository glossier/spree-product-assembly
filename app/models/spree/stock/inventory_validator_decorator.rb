module Spree
  module Stock
    module InventoryValidatorExtensions
      def validate(line_item)
        if line_item.inventory_units.count != quantity(line_item)
          line_item.errors[:inventory] << Spree.t(
            :inventory_not_available,
            item: line_item.variant.name
          )
        elsif line_item.insufficient_parts_selected?
          line_item.errors[:inventory] << Spree.t(
            :insufficient_parts_selected,
            item: line_item.variant.name
          )

        end
      end

      private

      def quantity(line_item)
        if line_item.has_parts? || line_item.product.phase_one_lite?
          line_item.part_line_items.count * line_item.quantity
        else
          line_item.quantity
        end
      end
    end
  end
end

::Spree::Stock::InventoryValidator.prepend ::Spree::Stock::InventoryValidatorExtensions
