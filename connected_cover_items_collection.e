<'
package cover_building_blocks;
struct connected_cover_items_collection {
    !cov_items_sets: list of cover_item_connected_set;

    build(all_cover_items: list of rf_simple_cover_item, out_file: string) is {
        cov_items_sets.clear();
        var total_size := all_cover_items.size();
        var xml_fh := files.open(out_file, "w", "xml output file");
        files.write(xml_fh, "<BlackBox>");
        for each(cov_item) in all_cover_items do {
            out(append("index = ", index, " out of: ", total_size));
            if filter_handler::to_filter(cov_item){
                continue;
            };
//            if cov_item.get_declaration().get_module().get_full_file_name() ~ "*example_6*" {
//            if cov_item.get_name() ~ "nmi" {
//            if index > 2804 {
//                break;
//            };
            out(append("cov item name: ", cov_item.get_name()
                    ,"\nmodule name: ", cov_item.get_declaration_module().get_name()
                    ,"\nline num: ", cov_item.get_declaration().get_source_line_num()
                    ,"\ncover group name: ",cov_item.get_cover_group().get_name()
                    ,"\nstruct name: ",cov_item.get_declaring_struct().get_name()
                ));
            out(append("start calc cov item: "), date_time());

            var conn_set := new cover_item_connected_set;
            conn_set.build(cov_item);
            try {
                var str_l := conn_set.to_xml("    ");
                files.write(xml_fh, str_join(str_l, "\n"));
            } else {
                out("issue write connected set to xml");
            };

            out(append("finish calc cov item: "), date_time());
            cov_items_sets.add(conn_set);
//            };
        };
        files.write(xml_fh, "</BlackBox>");
        files.close(xml_fh);
    };

//        return cov_items_sets;
};

'>
