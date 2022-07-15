<'

struct method_s {
    full_method_name: string;
    calling_method: rf_method;
    calling_layer: rf_method_layer;
};

struct port_s {
    method_port_ref : entity_reference;
    path            : string;
};

struct port_pair_s {
    in_method_port : port_s;
    out_method_port: port_s;
};

struct rf_wrapper{
    static base_txte_instance: rf_struct = NULL;
    static method_to_calling: list (key:full_method_name) of method_s;
    static port_connections: list of port_pair_s;
    static txte_agent_instances: list of string;

    static get_all_cover_items():list of rf_simple_cover_item is {
        var items:= rf_manager.get_user_types().all(it is a rf_struct).apply(it.as_a(rf_struct).get_declared_cover_groups()
            .apply(.get_all_items().all(it is a rf_simple_cover_item)).apply(it.as_a(rf_simple_cover_item)));
        return items;
    };

    static get_all_icon_structs(): list of rf_struct is {
        return rf_manager.get_user_types().all(it is a rf_struct).all(it.as_a(rf_struct).is_contained_in(rf_manager.get_struct_by_name(constants::ICON_BASE_CLASS_NAME))).apply(it.as_a(rf_struct));
    };
    
    static is_automatic_method(met_name: string): bool is {
        return met_name in constants::AUTOMATIC_METHOD_NAMES;
    };
    
    init() is also {
        method_to_calling.clear();
        port_connections.clear();
        txte_agent_instances.clear();
        base_txte_instance = rf_manager.get_user_types().all(it is a rf_struct).apply(it.as_a(rf_struct)).first(it.get_name() == "txte_msg_s");
//        rf_wrapper::build_methods_tree();
        rf_wrapper::build_connect_methods();
        rf_wrapper::build_txte_agent_instances_names();
    };
    
    static build_txte_agent_instances_names() is {
        var txte_instance_names := rf_manager.get_template_by_name("txte_intf_agent_u").get_all_instances().apply(.get_parameters()).apply(.as_a(rf_type_template_instance_parameter).get_type().get_name());
        rf_wrapper::txte_agent_instances.add(txte_instance_names);
    };
    
    static build_subscribe_methods() is {
        
    };
    
    static build_connect_methods() is {
        var all_usages_of_connect: list of port_pm_reference =
        lint_manager.get_port_pm_references("connect");
        var target_ref    : entity_reference;
        var param_refs    : list of entity_reference;
        var port1_field   : rf_field;
        var port2_field   : rf_field;
        var outport_path  : string;
        var inport_path   : string;

        for each (connect_usage) in all_usages_of_connect {
            target_ref = connect_usage.get_target_reference();
            outport_path = rf_wrapper::get_path_to_entity(target_ref);
            param_refs = connect_usage.get_pm_param_references();

            if target_ref != NULL and target_ref.get_entity() != NULL {
                port1_field = target_ref.get_entity().as_a(rf_field);

                if not param_refs.is_empty() and param_refs[0] != NULL {
                    var port2_entity := param_refs[0].get_entity();
                    if port2_entity != NULL {
                        port2_field = port2_entity.as_a(rf_field);
                        if port1_field.get_type() is a rf_method_port and port2_field.get_type() is a rf_method_port {
                            inport_path = rf_wrapper::get_path_to_entity(param_refs[0]);
                            rf_wrapper::port_connections.add(new with {
                                    .out_method_port = new port_s with {.method_port_ref = target_ref;   };
                                    .in_method_port  = new port_s with {.method_port_ref = param_refs[0];};
                                    });
                        };
                    };
                };
            };
        };
    };

    static get_path_to_entity(entity_ref : entity_reference) : string is {
        var target_ref := entity_ref;
        var dot := "";
        while target_ref != NULL {

            result = append(target_ref.get_entity().get_name(),
                dot, result);
            target_ref = target_ref.get_target_reference();
            dot = ".";
        };
    };

    static build_methods_tree() is {
        for each in lint_manager.get_all_entity_references({method}, "", "", FALSE) do {
            var called_meth: rf_method = it.get_entity().as_a(rf_method);
            var calling_layer: rf_method_layer = it.get_context().as_a(rf_method_layer);
            var calling_meth: rf_method;
            if calling_layer != NULL then {
                calling_meth = calling_layer.get_defined_entity().as_a(rf_method);
            };
            var called_namespace := (called_meth.get_declaring_struct() == NULL) ? "built_in" : called_meth.get_declaring_struct().get_name();
            var full_method_name := append(called_namespace,
                ":",
                called_meth.get_name());
            if method_to_calling.key_exists(full_method_name) {
            } else {
                method_to_calling.add(new method_s with {.full_method_name=full_method_name;
                        .calling_method=calling_meth;
                        .calling_layer=calling_layer;});
            };
        };
    };
};

'>