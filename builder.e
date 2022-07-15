<'
struct builder {
    !connected_cover_items_coll: connected_cover_items_collection;
    !rf_wrapper_handler        : rf_wrapper;
    !cache                     : cache;
    !csv_utils                 : csv_utils;

    init() is also {
        connected_cover_items_coll = new;
        rf_wrapper_handler         = new;
        cache                      = new;
    };

    build(filter_file: string, max_height: int, max_width: int, load_from_ascii: bool, ascii_struct_file: string, cluster: string) is {
        cache::named_entities_refs.clear();
        var xml_output_file_name := append(cluster, "_bbb_output.xml");
        if not load_from_ascii {
            if not (filter_file ~ "") {
                filter_handler::from_csv(filter_file);
            };
            var all_cover_items := rf_wrapper::get_all_cover_items();

            connected_cover_items_coll.build(all_cover_items, xml_output_file_name);
//            files.write_ascii_struct(ascii_struct_file, connected_cover_items_coll, date_time(), TRUE, 20, 10000);
//            out(append("ASCII struct info was dump to : ", ascii_struct_file));
        } else {
            connected_cover_items_coll = files.read_ascii_struct(ascii_struct_file, "connected_cover_items_collection").as_a(connected_cover_items_collection);
            out(append("ASCII struct info was read from : ", ascii_struct_file));
        };
//        var xml_output_file_name := append(cluster, "_bbb_output");
//        te_output_handler.write_data_to_xml(xml_output_file_name, connected_cover_items_coll.cov_items_sets.apply(it.as_a(data_s)));
        out(append("bbb info was dump to : ", xml_output_file_name));
        out(append("Finished Successfully at: ", date_time()));

//        te_output_handler.write_data_to_xml("bbb_output", connected_cover_items_coll.build(all_cover_items));
//        var all_icon_structs_items := rf_wrapper::get_all_icon_structs()
    };
};

extend sys {
    !builder: builder;
    init() is also {
        builder = new;
    };

    setup() is also {
        set_config(print, line_size, 140);
        set_config(run, error_command, "");
        set_config(misc, lint_mode, TRUE);
    };
};

'>