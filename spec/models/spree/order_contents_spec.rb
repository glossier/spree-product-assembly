describe Spree::OrderContents, type: :model do
  describe "#add_to_line_item" do
    context "given a variant which is an assembly" do
      it "creates a PartLineItem for each part of the assembly" do
        order = create(:order)
        assembly = create(:product)
        pieces = create_list(:product, 2)
        pieces.each do |piece|
          create(:assemblies_part, assembly: assembly.master, part: piece.master)
        end

        contents = described_class.new(order)

        line_item = contents.add_to_line_item_with_parts(assembly.master, 1)

        part_line_items = line_item.part_line_items

        expect(part_line_items[0].line_item_id).to eq line_item.id
        expect(part_line_items[0].variant_id).to eq pieces[0].master.id
        expect(part_line_items[0].quantity).to eq 1
        expect(part_line_items[1].line_item_id).to eq line_item.id
        expect(part_line_items[1].variant_id).to eq pieces[1].master.id
        expect(part_line_items[1].quantity).to eq 1
      end
    end

    context "given parts of an assembly" do
      it "creates a PartLineItem for each part" do
        setup_order_and_bundle_with_variants

        part_line_items = @line_item.part_line_items

        expect(part_line_items[0].line_item_id).to eq @line_item.id
        expect(part_line_items[0].variant_id).to eq @keychain.master.id
        expect(part_line_items[0].quantity).to eq 1
        expect(part_line_items[1].line_item_id).to eq @line_item.id
        expect(part_line_items[1].variant_id).to eq @shirt.variants.last.id
        expect(part_line_items[1].quantity).to eq 1
      end

      it "creates a new line item when parts do not match" do
        setup_order_and_bundle_with_variants

        # adds the second item

        second_bundle = @contents.add_to_line_item_with_parts(@assembly.master, 1, {
          selected_variants: [@keychain.master.id, @shirt.variants.first.id]
        })

        bundle_with_parts_matching = @contents.add_to_line_item_with_parts(@assembly.master, 1, {
          selected_variants: [@keychain.master.id, @shirt.variants.last.id]
        })

        expect(@order.line_items.count).to eq 2
        expect(@order.line_items.first.quantity).to eq 2
        expect(@order.line_items.last.quantity).to eq 1 
      end
    end
  end

  def setup_order_and_bundle_with_variants
    @order = create(:order)
    @assembly = create(:product)

    red_option = create(:option_value, presentation: "Red")
    blue_option = create(:option_value, presentation: "Blue")

    option_type = create(:option_type,
                         presentation: "Color",
                         name: "color",
                         option_values: [
                           red_option,
                           blue_option
                         ])

    @keychain = create(:product_in_stock)

    @shirt = create(:product_in_stock,
                   option_types: [option_type],
                   can_be_part: true)

    create(:variant_in_stock, product: @shirt, option_values: [red_option])
    create(:variant_in_stock, product: @shirt, option_values: [blue_option])

    assembly_part_keychain = create(:assemblies_part,
           assembly_id: @assembly.id,
           part_id: @keychain.master.id)
    assembly_part_shirt = create(:assemblies_part,
           assembly_id: @assembly.id,
           part_id: @shirt.master.id,
           variant_selection_deferred: true)
    @assembly.reload

    @contents = Spree::OrderContents.new(@order)

    @line_item = @contents.add_to_line_item_with_parts(@assembly.master, 1, {
      selected_variants: [@keychain.master.id, @shirt.variants.last.id]
    })
  end
end
