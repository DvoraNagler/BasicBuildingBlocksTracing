<'
package cover_building_blocks;

struct cover_item_connected_set {
    !related_cover_item: basic_building_block;
    !bfs_queue: list of basic_building_block;

    build(cov_item: rf_simple_cover_item) is {
        var te_bb_item: basic_building_block = new cover_item basic_building_block;
        var level := 0;
        te_bb_item.build(cov_item, level);
        related_cover_item = te_bb_item;
        bfs_queue.add(te_bb_item);
        repeat {
            var bb_item := bfs_queue.pop0();
            if bb_item.kind != cover_item {
                bb_item.parent_cover_item = related_cover_item.as_a(cover_item basic_building_block);
            };
            if bb_item.search_until_root() {
                continue;
            };
            if bb_item.level > constants::DEFAULT_MAX_BFS_HEIGHT {
                out(append("BREAK BFS SEARCH due to: graph height bigger than ",
                        constants::DEFAULT_MAX_BFS_HEIGHT));
                return;
            };

            var bb_neighbors_items : list of basic_building_block;
            var cache_res := cache::get(bb_item.rf_named_entity);
            if cache_res.is_hit() {
                var cache_ptr := cache_res.bb_item_ptr;
                //Sometimes, we need also to take info from the bbb item itself and not only it's children list
                //(i.e in method, we're taking classification info)
                bb_item.update_by_cache_info(cache_ptr);
//                var terminator_l: list of terminator = basic_building_block::get_terminator_l_in_sub_tree(cache_ptr);
//
//                if terminator_l.size() > 0 {
//                    bb_item.parent_cover_item.any_driver_identified = TRUE;
//                    bb_item.parent_cover_item.terminator_l.add(terminator_l);
//                };
                bb_item.children_l = cache_ptr.children_l;

            } else {
                bb_neighbors_items = bb_item.get_adjustment_neighbors();

                for each (child) in bb_neighbors_items {
                    var child_validity := is_child_valid(bb_item, child);
                    if child_validity {
                        child.update_parent(bb_item);
                        bb_item.children_l.add(child);
                    };
                };


//                var terminator_elem := bb_item.get_terminator();
//                if terminator_elem != NULL {
//                    related_cover_item.as_a(cover_item basic_building_block).terminator_l.add(terminator_elem);
//                    related_cover_item.as_a(cover_item basic_building_block).any_driver_identified = TRUE;
//                    bb_item.terminator_inst = terminator_elem;
//                };

                for each (bb_neigh) in bb_item.children_l{
                    bb_neigh.update_level(bb_item.level + 1);
                    if bfs_queue.count(it.level == bb_item.level + 1) > constants::DEFAULT_MAX_BFS_WIDTH {
                        out(append("BREAK BFS SEARCH due to: in level ",
                                bb_item.level + 1,
                                " there are more than ",
                                constants::DEFAULT_MAX_BFS_WIDTH,
                                " children"));
                        return;
                    } else {
                        bfs_queue.add(bb_neigh);
                    };
                };

                cache::update(bb_item.rf_named_entity, bb_item);
            };

        } until bfs_queue.is_empty() == TRUE;

    };

    to_xml(indent: string="") : list of string is {
        update_terminators();
        var prefix_conn_set: string = append(indent, "<connected_set>");
        result.add(prefix_conn_set);
        var new_indent := "    ";

        var root := related_cover_item;
        var curr := root;
        result.add(root.to_xml(new_indent));
        var postfix_conn_set: string = append(indent, "</connected_set>");
        result.add(postfix_conn_set);
    };

    update_terminators() is {
        var root := related_cover_item.as_a(cover_item basic_building_block);
        var terminator_l : list of terminator;
        var queue: list of basic_building_block;
        queue.add(root);
        repeat {
            var elem := queue.pop0();
            for each (child) in elem.children_l do {
                if child.children_l.is_empty() {
                    var terminator_inst := child.get_terminator();
                    if terminator_inst != NULL {
                        terminator_l.add(terminator_inst);
                    };
                };
            };
            queue.add(elem.children_l);

        } until (queue.is_empty());
        if not terminator_l.is_empty() {
            root.terminator_l.add(terminator_l);
            root.any_driver_identified = TRUE;
        };
    };

    is_child_valid(parent: basic_building_block, child: basic_building_block): bool is {
        var is_valid := child.kind != cover_item and not field_is_cover_item(child) and child.rf_named_entity not in parent.children_l.rf_named_entity and not basic_building_block::search_until_root_by_child(child, parent);
        result = is_valid;
    };

    field_is_cover_item(child: basic_building_block): bool is {
        result = FALSE;
        if child.rf_named_entity != NULL and child.rf_named_entity is a rf_field(field) {
            if field.get_declaring_struct().get_name() ~ "/^cover__/" {
                result = TRUE;
            };
        };
    };


};

'>