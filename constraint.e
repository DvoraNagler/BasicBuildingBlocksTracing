<'
extend basic_building_block {
    when constraint basic_building_block {
        ref_con: rf_constraint;

        build(ref_ent: rf_named_entity, graph_level: uint=0) is also {
            ref_con = ref_ent.as_a(rf_constraint);
            level = graph_level;
        };

        get_adjustment_neighbors(): list of basic_building_block is {
            var neighbors := lint_manager.get_all_entity_references_in_context(ref_con.get_declaration(), {field;method;constraint}).apply(me.from_entity_reference(it));
            return neighbors;
//            only here i know that is terminator
        };

        get_terminator(): terminator is {
            if children_l.is_empty() {
                result = new terminator with {.is_txte=FALSE; .leaf_bbb_ref=me; .reason=constraint_without_ent_refs; };
            };
        };

        get_attributes(): string is also {
            if children_l.is_empty() {
                result = append(result, " is_terminator=", quote(TRUE.as_a(string)));
            };
        };
    };
};

'>