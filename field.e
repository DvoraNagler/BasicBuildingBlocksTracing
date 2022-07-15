<'
extend basic_building_block{
    when field basic_building_block{
        ref_f: rf_field;
        !is_txte: bool;
        !tlm_name: string;
        !is_physical: bool;
        !contained_directly_in_txte_inst: bool;

        build(ref_ent: rf_named_entity, graph_level: uint=0) is also {
            ref_f = ref_ent.as_a(rf_field);
            level = graph_level;
            contained_directly_in_txte_inst = FALSE;
        };

        get_adjustment_neighbors(): list of basic_building_block is {
            is_txte = FALSE;
            is_physical = ref_f.is_physical();
            if ref_f.get_declaring_struct().is_contained_in(rf_wrapper::base_txte_instance) {
                is_txte = TRUE;
                contained_directly_in_txte_inst = TRUE;
                tlm_name = str_replace(ref_f.get_declaring_struct().get_name(),constants::POSTFIX_TXTE_STRUCT_NAME,"");
                return result;
            } else if ref_f.get_declaration().get_module().get_name() ~ constants::TXTE_STRUCTS_MODULE_NAME {
                var target_ref: entity_reference;
                target_ref = en_ref.get_target_reference();
                if target_ref != NULL {
                    repeat {
                        var ent := target_ref.get_entity();
                        if ent is a rf_struct_member (member){
                            if member.get_declaring_struct().is_contained_in(rf_wrapper::base_txte_instance) {
                                is_txte = TRUE;
                                contained_directly_in_txte_inst = FALSE;
                                tlm_name = str_replace(member.get_declaring_struct().get_name(),constants::POSTFIX_TXTE_STRUCT_NAME,"");
                                break;
                            };
                        };
                        target_ref = target_ref.get_target_reference();
                    } until target_ref == NULL;
                };
                return result;
            };
            var ent_refs := lint_manager.get_entity_references(ref_f,"",TRUE);
            return ent_refs.all(!(it.get_context() is a rf_cover_item_layer)).apply(me.from_context_layer(it, TRUE)).all(it != NULL);
        };

        get_terminator(): terminator is {
            if is_txte {
                if contained_directly_in_txte_inst {
                    result = new txte_terminator with {.is_txte=is_txte; .leaf_bbb_ref=me; .reason=contained_in_base_txte_inst; .tlm_name=tlm_name;};
                } else {
                    result = new txte_terminator with {.is_txte=is_txte; .leaf_bbb_ref=me; .reason=one_of_target_contained_in_base_txte_inst; .tlm_name=tlm_name;};
                };
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