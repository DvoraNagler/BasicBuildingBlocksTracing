<'
extend basic_building_block {
    when enum_item basic_building_block {
        !enum_item: rf_enum_item;
        !is_txte: bool;
        !tlm_name: string;

        build(ref_ent: rf_named_entity, graph_level: uint=0) is also {
            enum_item = ref_ent.as_a(rf_enum_item);
            level = graph_level;
            set_is_txte();
        };

        get_adjustment_neighbors(): list of basic_building_block is {

        };

        get_terminator(): terminator is {
            if is_txte {
                result = new txte_terminator with {.is_txte=is_txte; .leaf_bbb_ref=me; .reason=txte_enum_item; .tlm_name=tlm_name;};
            };
        };

        set_is_txte() is {
            is_txte = FALSE;
            var proposed_tlm_name := str_lower(str_replace(enum_item.get_name(), constants::PREFIX_TXTE_STRUCT_NAME, ""));
            var intf_agent_name := append(proposed_tlm_name, constants::POSTFIX_TXTE_STRUCT_NAME);
            if intf_agent_name in rf_wrapper::txte_agent_instances {
                is_txte = TRUE;
                tlm_name = proposed_tlm_name;
            };
        };

        get_attributes(): string is also {
            if is_txte {
                result = append(result, " is_txte=", quote(is_txte.as_a(string)), " tlm_name=", quote(tlm_name));
            };
        };
    };
};
'>
