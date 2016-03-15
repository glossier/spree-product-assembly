module Spree
  module Api
    module LineItemsControllerExtensions

      def self.prepended(base)
        base.prepend_before_action :permit_selected_parts, only: [:create]
      end

      def permit_selected_parts
        self.line_item_options += [:selected_parts]
      end


    end
  end
end
::Spree::Api::LineItemsController.prepend Spree::Api::LineItemsControllerExtensions
