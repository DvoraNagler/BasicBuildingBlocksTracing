<'

extend basic_building_block {
    when cover_item basic_building_block {
        cov_item_f            : rf_simple_cover_item;
        !declared_struct_name : string;
        !cov_group_name       : string;
        !any_driver_identified: bool;
        !terminator_l         : list of terminator;
        
        build(rf_cov_item: rf_named_entity, graph_level: uint=0) is also{
            cov_item_f = rf_cov_item.as_a(rf_simple_cover_item);
            level = graph_level;
            declared_struct_name = cov_item_f.get_declaring_struct().get_name();
            cov_group_name = cov_item_f.get_cover_group().get_name();
            any_driver_identified = FALSE;
        };

        get_adjustment_neighbors(): list of basic_building_block is{
            var neighbors := lint_manager.get_all_entity_references_in_context(cov_item_f.get_declaration(), {field;method}).apply(me.from_entity_reference(it, TRUE));
            return neighbors;
//            TODO Dvora check if field declaration context is the same as cov item context
        };

        get_attributes(): string is also{
            var identifiers_attr: string = "";
            if any_driver_identified {
                identifiers_attr = str_join(terminator_l.reason.sort(it).unique(it).apply(.as_a(string)), ";");
            };
            result = append(result, " declared_struct_name=", quote(declared_struct_name), 
                " cov_group_name=", quote(cov_group_name), 
                " any_driver_identified=", quote(any_driver_identified.as_a(string)), 
                " identifiers=", quote(identifiers_attr));
        };
    };
};
'>