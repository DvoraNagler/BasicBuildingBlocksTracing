<'
struct constants {
    static !TXTE_BASE_CLASS_NAME     : string         = "txte_msg_s";   
    static !ICON_BASE_CLASS_NAME     : string         = "any_const_cfg_s";
    static !CONNECT_PORTS_METHOD_NAME: string         = "connect_ports";
    static !PREFIX_TXTE_STRUCT_NAME  : string         = "TXTE_MSG_";
    static !POSTFIX_TXTE_STRUCT_NAME : string         = "_data_s";
    static !SUBSCRIBE_METHOD_NAME    : string         = "subscribe";
    static !CONNECT_METHOD_NAME      : string         = "connect";
    static !TXTE_STRUCTS_MODULE_NAME : string         = "txte_tlm_top_intf_structs";
    
    static !AUTOMATIC_METHOD_NAMES   : list of string = {"init";"pre_generate";"post_generate";
                                                         "connect_ports";"run";"extract";"check";
                                                         "setup";"finalize"};
    static !ENUM_ITEM_TXTE_BASE_NAME : string         = "txte_msg_type_t";
    static !TXTE_AGENT_STRUCT_NAME   : string         = "txte_intf_agent_u";
    static !DEFAULT_MAX_BFS_HEIGHT   : int            = 10;
    static !DEFAULT_MAX_BFS_WIDTH    : int            = 20;
    
};


'>