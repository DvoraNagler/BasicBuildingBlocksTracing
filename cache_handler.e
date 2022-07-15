<'
type cache_result_kind:[hit, miss];

struct mem_item {
    named_entity: rf_named_entity;
//    TODO here to save the father only and not list of 
    bb_item_ptr: basic_building_block;
};

struct cache_result {
    !kind: cache_result_kind;
    !bb_item_ptr: basic_building_block;
    
    is_hit(): bool is {
        return kind == hit;
    };
};

struct cache {
    static !named_entities_refs: list(key: named_entity) of mem_item;

    static get(named_entity: rf_named_entity): cache_result is {
        if named_entities_refs.key_exists(named_entity) {
            out("cache hit");
            return new cache_result with {.kind=hit; .bb_item_ptr=cache::named_entities_refs.key(named_entity).bb_item_ptr;};
        } else {
            return new cache_result with {.kind=miss;};
        };
    };

    static update(named_entity: rf_named_entity, refs: basic_building_block) is {
        if not named_entities_refs.key_exists(named_entity) {
            named_entities_refs.add(new mem_item with {.named_entity = named_entity; .bb_item_ptr = refs; });
        };
    };
    
    static reset_cache_rf_pointers() is {
        for each (mem_item) in cache::named_entities_refs do {
            mem_item.bb_item_ptr.reset_rf_pointers();
        };
    };
    
};

'>
