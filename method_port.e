<'
extend basic_building_block{
    when method_port basic_building_block{
        !ref_m: rf_method_port;

        build(ref_ent: rf_named_entity, graph_level: uint=0) is also {
            ref_m = ref_ent.as_a(rf_field).get_type().as_a(rf_method_port);
            level = graph_level;
        };

        get_adjustment_neighbors(): list of basic_building_block is {
            var neighbors := lint_manager.get_entity_references(rf_named_entity.as_a(rf_field),"",TRUE).apply(me.from_context_layer(it, TRUE));
            return neighbors;
        };


    };
};
'>