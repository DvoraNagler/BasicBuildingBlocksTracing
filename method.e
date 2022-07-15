<'

extend basic_building_block{
    when method basic_building_block {
        !ref_m: rf_method;
//      !params_l: list of method_parameter;
        !in_mp_field : rf_field;
        !classification: method_classification_t;

        build(ref_ent: rf_named_entity, graph_level: uint=0) is also {
            ref_m = ref_ent.as_a(rf_method);
//            params_l = ref_m.get_parameters().apply(method_parameter::from_rf_param(it));
            level = graph_level;
            classification = none;
        };

        update_by_cache_info(cache_ptr: basic_building_block) is also {
            me.classification = cache_ptr.as_a(method basic_building_block).classification;
        };

        get_terminator(): terminator is {
            if classification == automatic {
                result = new terminator with {.is_txte=FALSE; .leaf_bbb_ref=me; .reason=automatic_method; };
            };
        };

        when  active basic_building_block{
            get_adjustment_neighbors(): list of basic_building_block is also {
                result.add(lint_manager.get_all_entity_references_in_context(ref_m.get_declaration(),{field;method}).apply(me.from_entity_reference(it, TRUE)));
            };
        };

        when  passive basic_building_block{

            get_adjustment_neighbors(): list of basic_building_block is also {
                //todo related param maybe it's type from struct inherit from TXTE_BASE_CLASS_NAME
                //var params_l := ref_m.get_parameters().has(it.get_type().get_name() == TXTE_BASE_CLASS_NAME);
                //var is_met_port := ref_m.get_declaring_struct().get_declared_fields().has(it.get_type() == rf_method_port and it.get_name() == ref_m.get_name() and it.as_a(rf_method_port).is_input());

//            result.add(get_called_method_building_blocks());
//            var conn_port := rf_wrapper::port_connections.first(it.in_method_port.path ~ called_met.)
                var is_automatic := automatic_method_handler();
                if not is_automatic {
                    if not is_in_mp() {
                        //Case: Out-MP or regular method
                        result = find_method_refs_from_context();
                    } else {
                        //Case: In-MP
                        result = find_method_refs_for_in_mp();
                    };
                    update_classification(result.is_empty());
                };

            };

            automatic_method_handler(): bool is {
                result = FALSE;
                if rf_wrapper::is_automatic_method(ref_m.get_name()) {
                    classification = automatic;
                    result = TRUE;
                };
                return result;
            };

            find_method_refs_from_context(): list of basic_building_block is {
                var method_refs := lint_manager.get_entity_references(ref_m,"",TRUE).apply(me.from_context_layer(it, TRUE)).all(it != NULL);
                method_refs = method_refs.all(.rf_named_entity != ref_m);
                result.add(method_refs);
            };

            find_method_refs_for_in_mp(): list of basic_building_block is {
                var in_mp_field_refs := get_in_mp_field_building_blocks();
                if not in_mp_field_refs.is_empty() {
                    result.add(in_mp_field_refs);
                } else {
                    var mp_refs := get_mp_refs();
                    result.add(mp_refs);
                };
            };

            update_classification(is_empty_result: bool) is {
                if is_empty_result {
                    classification = unused;
                };
            };

            get_mp_refs() : list of basic_building_block is {
                var ent_ref: entity_reference;
                for each (port_conn) in rf_wrapper::port_connections {
                    var out_method_ref := port_conn.out_method_port.method_port_ref;
                    var in_method_ref := port_conn.in_method_port.method_port_ref;
                    if in_method_ref.get_entity().get_name() ~ ref_m.get_name(){
                        result.add(from_entity_reference(out_method_ref));
                        break;
                    }
                };
            };

//        get_called_method_building_blocks(): list of basic_building_block is {
//            var called_met := rf_wrapper::method_to_calling.key(append(ref_m.get_declaring_struct().get_name(),
//                    ":",
//                    ref_m.get_name()));
//            if (called_met != NULL and called_met.calling_method != NULL){
//                result.add(me.from_named_entity(called_met.calling_method));
//            };
//        };

            is_in_mp(): bool is {
                var port_instance_l := ref_m.get_declaring_struct().get_declared_fields().all(it.is_port_instance());
                for each (port_inst) in port_instance_l {
                    if port_inst.get_type() is a rf_port {
                        if port_inst.get_type().as_a(rf_port).is_input() and port_inst.get_name() ~ ref_m.get_name(){
                            in_mp_field = port_inst;
                            break;
                        };
                    } else if port_inst.get_type().as_a(rf_list).get_element_type().as_a(rf_port).is_input(){
                        in_mp_field = port_inst;
                        break;
                    };
                };

                return in_mp_field != NULL;
            };

            get_in_mp_field_building_blocks() : list of basic_building_block is {
                var in_mp_field_context_refs := lint_manager.get_entity_references(in_mp_field,"",TRUE).apply(.get_context());
                for each (in_mp_field_ref) in in_mp_field_context_refs {
                    if in_mp_field_ref.get_defined_entity().get_name() ~ constants::CONNECT_PORTS_METHOD_NAME {
                        var refs_in_context := lint_manager.get_all_entity_references_in_context(in_mp_field_ref, {});
                        var first_ref_field_idx := refs_in_context.first_index(.get_entity().get_name() ~ ref_m.get_name());
                        if first_ref_field_idx == -1 {
                            return result;
                        };
                        var subscribe_idx : int = UNDEF;
                        for ref_idx from first_ref_field_idx down to 0 do {
                            var ent_name := refs_in_context[ref_idx].get_entity().get_name();
                            if ent_name ~ constants::CONNECT_METHOD_NAME {
                                return result;
                            } else if ent_name ~ constants::SUBSCRIBE_METHOD_NAME {
                                subscribe_idx = ref_idx;
                                break;
                            };
                        };

                        if subscribe_idx == UNDEF {
                            return result;
                        };

                        for relevant_ref_idx from subscribe_idx to first_ref_field_idx do {
                            var ref_in_cxt := refs_in_context[relevant_ref_idx];
                            var ref_in_cxt_ent := ref_in_cxt.get_entity();
                            var is_txte_enum_item: bool = ref_in_cxt_ent is a rf_enum_item and ref_in_cxt_ent.as_a(rf_enum_item).get_defining_type().get_name() ~ constants::ENUM_ITEM_TXTE_BASE_NAME;
                            if is_txte_enum_item {
                                result.add(me.from_context_layer(ref_in_cxt));
                            };
                        };
                    };
                };
            };

            get_attributes(): string is also {
                result = append(result, " method_classification=", quote(classification.as_a(string)));
                if classification == automatic  {
                    result = append(result, " is_terminator=", quote(TRUE.as_a(string)));
                };
            };
        };
    };
};
'>