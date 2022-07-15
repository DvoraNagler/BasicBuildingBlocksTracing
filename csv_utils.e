<'
struct csv_utils {
    static read_csv(file_path: string, skip_header: bool): list of list of string is {
        var skip_done := (skip_header) ? FALSE : TRUE;
        if files.file_exists(file_path){
            for each line(csv_l) in file file_path {
//              check it's not a comment
                if csv_l ~ "/^#/" {
                    continue;
                };
//              check it's not the header
                if not skip_done  {
                    skip_done = TRUE;
                    continue;
                };
                var splitted_l := str_split(csv_l,",");
                result.add(splitted_l);
            };
        };
        return result;
    };
};
'>
