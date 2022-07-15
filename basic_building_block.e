<'
package cover_building_blocks;


struct terminator {
    !is_txte     : bool;
    !leaf_bbb_ref: basic_building_block;
    !reason      : bb_terminator_kind_t;
};

struct txte_terminator like terminator {
    !tlm_name: string;
};

struct basic_building_block {
    !kind                  : bb_kind_t;
    !activation_mode       : method_operation_mode_t;
    !rf_named_entity       : rf_named_entity;
    !en_ref                : entity_reference;
    !path                  : string;
    !level                 : uint;
    !children_l            : list of basic_building_block;
    !entity_name           : string;
    !parent                : basic_building_block;
    !terminator_inst       : terminator;
    !parent_cover_item     : cover_item basic_building_block;

    build(ref_ent: rf_named_entity, graph_level: uint=0) is {
        rf_named_entity = ref_ent;
        entity_name = ref_ent.get_name();
    };

    get_adjustment_neighbors(): list of basic_building_block is {

    };

    update_by_cache_info(cache_ptr: basic_building_block) is {

    };

    static get_terminator_l_in_sub_tree(cache_ptr: basic_building_block): list of terminator is {
        var terminator_l : list of terminator;
        var queue: list of basic_building_block;
        queue.add(cache_ptr);
        repeat {
            var elem := queue.pop0();
            for each (child) in elem.children_l do {
                if child.terminator_inst != NULL {
                    terminator_l.add(child.terminator_inst);
                };
            };
            queue.add(elem.children_l);

        } until (queue.is_empty());
        return terminator_l;
    };

    update_parent(parent: basic_building_block) is {
        me.parent = parent;
    };

    get_terminator(): terminator is {

    };

    update_level(graph_level: uint) is {
        level = graph_level;
    };

    search_until_root(): bool is {
        result = FALSE;
        var curr := parent;
        if curr == NULL {
            return result;
        };
        repeat {
            if curr.rf_named_entity == rf_named_entity {
                result = TRUE;
                return result;
            };
            curr = curr.parent;

        } until (curr == NULL);
    };

    static search_until_root_by_child(child: basic_building_block, parent:basic_building_block): bool is {
        result = FALSE;
        var curr := parent;
        if curr == NULL {
            return result;
        };
        repeat {
            if curr.rf_named_entity == child.rf_named_entity {
                result = TRUE;
                return result;
            };
            curr = curr.parent;

        } until (curr == NULL);
    };

    from_entity_reference(en_ref: entity_reference, called_by_cover_item: bool = FALSE): basic_building_block is {
        var entity := en_ref.get_entity();
        result = build_entity(entity, called_by_cover_item);
        result.en_ref = en_ref;
        result.path = rf_wrapper::get_path_to_entity(en_ref);
    };

    from_context_layer(en_ref: entity_reference, to_use_defined_entity: bool = FALSE): basic_building_block is {
        var definition_elem := en_ref.get_context();
        if definition_elem == NULL {
            return NULL;
        };
        var ref_to_build := to_use_defined_entity ? definition_elem.get_defined_entity() : en_ref.get_entity();
        result = build_entity(ref_to_build);
        if result != NULL {
            result.en_ref = en_ref;
            result.path = rf_wrapper::get_path_to_entity(en_ref);
        };
    };

    build_entity(entity: rf_named_entity, called_by_cover_item: bool = FALSE): basic_building_block is {
        case {
            entity is a rf_method {
                if called_by_cover_item {
                    result = new active method basic_building_block;
                } else {
                    result = new passive method basic_building_block;
                };

                result.build(entity);
            };
            entity is a rf_constraint {
                result = new constraint basic_building_block;
                result.build(entity);
            };
            entity is a rf_simple_cover_item {
                result = new cover_item basic_building_block;
                result.build(entity);
            };
            entity is a rf_field {
                if entity.as_a(rf_field).get_type() is a rf_method_port {
                    result = new method_port basic_building_block;
                    result.build(entity);
                }
                else {
                    result = new field basic_building_block;
                    result.build(entity);
                };

            };
            entity is a rf_enum_item {
                result = new enum_item basic_building_block;
                result.build(entity);
            };

        };
    };

    reset_rf_pointers() is {
        rf_named_entity = NULL;
        en_ref = NULL;
    };

    to_xml(indent: string = "")  : list of string is {
        var block_header: string = append(indent, "<basic_building_block" , get_attributes());
        if children_l is not empty {
            result.add(append(block_header, ">"));
            for each (child) in children_l {
                result.add(child.to_xml(append(indent,"    ")));
            };
            result.add(append(indent, "</basic_building_block>"));
        } else {
            result.add(append(block_header, "/>"));
        };
        return result;
    };

    get_attributes(): string is {
        result = append(" name=", quote(entity_name), " path=", quote(path), " type=", quote(append(kind)));
    };


};

'>