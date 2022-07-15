<'

struct base_match {
    !cov_item: rf_simple_cover_item;
    !other_string: string;

    match() : bool is empty;
    get_value_from_cov(): string is empty;
};

struct match_file_path like base_match {
    get_value_from_cov(): string is {
        result = cov_item.get_declaration().get_module().get_full_file_name();
    };

    match(): bool is {
        result = get_value_from_cov() ~ append("*",other_string,"*")
    };
};

struct match_base_cls like base_match {
    get_value_from_cov(): string is {
        var declaring_st := cov_item.get_declaring_struct();
        if declaring_st is a rf_like_struct (like_st) {
            result = like_st.get_supertype().get_name();
        } else if declaring_st is a rf_when_subtype (when_st) {
            result = when_st.get_when_base().get_name();
        };
    };

    match(): bool is {
        result = (other_string != "") ? FALSE: TRUE;
        if other_string != "" {
            var super_name := get_value_from_cov();
            result = super_name ~ other_string;
        };
    };
};

struct match_struct_name like base_match {
    get_value_from_cov(): string is {
        result = cov_item.get_declaring_struct().get_name();
    };

    match(): bool is {
        if other_string ~ "" {
            result = TRUE;
        } else {
            result = get_value_from_cov() ~ other_string;
        };
    };
};

struct match_cover_grp_name like base_match {
    get_value_from_cov(): string is {
        result = cov_item.get_cover_group().get_name();
    };

    match(): bool is {
        if other_string ~ "" {
            result = TRUE;
        } else {
            result = get_value_from_cov() ~ other_string;
        };
    };
};

struct match_cover_item_name like base_match {
    get_value_from_cov(): string is {
        result = cov_item.get_name();
    };

    match(): bool is {
        if other_string ~ "" {
            result = TRUE;
        } else {
            result = get_value_from_cov() ~ other_string;
        };
    };
};

struct filter_line {
    !string_contains_in_file_path: string;
    !base_cls_name: string;
    !struct_name: string;
    !cover_grp_name: string;
    !cov_item_name: string;
    !comment: string;
    !match_reqs: list of base_match;

    initialize(from_csv_line: bool, cov_item: rf_simple_cover_item) is {
        match_reqs.clear();
        match_reqs.add(new match_file_path with {
                .cov_item=cov_item;
                .other_string=(from_csv_line) ? string_contains_in_file_path: "";
            });

        match_reqs.add(new match_base_cls with {
                .cov_item=cov_item;
                .other_string=(from_csv_line) ? base_cls_name: "";
            });

        match_reqs.add(new match_struct_name with {
                .cov_item=cov_item;
                .other_string=(from_csv_line) ? struct_name: "";
            });

        match_reqs.add(new match_cover_grp_name with {
                .cov_item=cov_item;
                .other_string=(from_csv_line) ? cover_grp_name: "";
            });

        match_reqs.add(new match_cover_item_name with {
                .cov_item=cov_item;
                .other_string=(from_csv_line) ? cov_item_name: "";
            });
    };

    to_filter(cov_item: rf_simple_cover_item): bool is {
        initialize(TRUE, cov_item);
        result = not match_reqs.has(!.match());
    };

    from_cov_item(cov_item: rf_simple_cover_item) is {
        initialize(FALSE, cov_item);
        string_contains_in_file_path = match_reqs.first(it is a match_file_path).get_value_from_cov();
        base_cls_name = match_reqs.first(it is a match_base_cls).get_value_from_cov();
        struct_name = match_reqs.first(it is a match_struct_name).get_value_from_cov();
        cover_grp_name = match_reqs.first(it is a match_cover_grp_name).get_value_from_cov();
        cov_item_name = match_reqs.first(it is a match_cover_item_name).get_value_from_cov();
    };

    to_csv(): string is {
        return append(string_contains_in_file_path, "," , base_cls_name, "," , struct_name, "," , cover_grp_name , "," , cov_item_name, ",", comment);
    };
};

struct filter_handler {
    static !filter_line_coll: list of filter_line;

    static from_csv(filter_file_path: string) is {
        filter_handler::filter_line_coll.clear();
        var filters_content_l := csv_utils::read_csv(filter_file_path, TRUE);
        for each (filter_l) in filters_content_l do {
            filter_handler::filter_line_coll.add(new filter_line with {
                    .string_contains_in_file_path = filter_l[0];
                    .base_cls_name = filter_l[1];
                    .struct_name = filter_l[2];
                    .cover_grp_name = filter_l[3];
                    .cov_item_name = filter_l[4];
                    .comment = filter_l[5];
                });
        };
    };

    static to_filter(cov_item: rf_simple_cover_item): bool is {
        for each (filter_line) in filter_handler::filter_line_coll do{
            if filter_line.to_filter(cov_item) {
                result = TRUE;
                return result;
            };
        };
        result = FALSE;
    };

    static add_from_cov(cov_item: rf_simple_cover_item) is {
        filter_handler::filter_line_coll.add(new filter_line with {.comment = "auto generated";});
        filter_handler::filter_line_coll[filter_handler::filter_line_coll.size() - 1].from_cov_item(cov_item);
    };

    static write_filter_file(file_name: string) is {
        var m_file: file = files.open(file_name, "w", "Filter File");
        for each (filter_line) in filter_handler::filter_line_coll do{
            files.write(m_file, filter_line.to_csv());
        };
        m_file.close();
    };
};
'>
