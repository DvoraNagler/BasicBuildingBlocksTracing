<'
struct configuration_line {
    !cluster: string;
    !max_bfs_tree_height: int;
    !max_bfs_tree_width: int;
};

struct configuration {
    !cfg_lines: list of configuration_line;

    static parse(cfg_file_path: string) is {
        filter_handler::filter_line_coll.clear();
        var csv_content := csv_utils::read(filter_file_path);
        if files.file_exists(filter_file_path){
            for each line(filter_l) in file filter_file_path {
//                check it's not a comment
                if filter_l ~ "/^#/" {
                    continue;
                };
//                check it's not the header
                if filter_l ~ "string_contain*" {
                    continue;
                };
                var splitted_filter_l := str_split(filter_l,",");
                filter_handler::filter_line_coll.add(new filter_line with {
                        .string_contains_in_file_path = splitted_filter_l[0];
                        .base_cls_name = splitted_filter_l[1];
                        .struct_name = splitted_filter_l[2];
                        .cover_grp_name = splitted_filter_l[3];
                        .cov_item_name = splitted_filter_l[4];
                        .comment = splitted_filter_l[5];
                    });
            };
        };
    };
};
'>
