// -----------------------------------------------------------------------
// Title             : $RCSfile: $ $Date: $
// Project           : Skylake
// -----------------------------------------------------------------------
// Primary Contact   : Chico <yehezkel-chico.zadik@intel.com>
// Secondary Contact : 
// Prev.proj Contact : 
// Creation Date     : 2022/2/25
// -----------------------------------------------------------------------
// Copyright (c) 2010 by Intel Corporation. This information is the
// confidential and proprietary property of Intel Corporation and
// the possession or use of this file requires a written license
// from Intel Corporation.
// -----------------------------------------------------------------------
// Description :
// This find all ports that are defined in interpreted files of this TE
// and create a list of ports and thier related connections, including
// connection to the router output, in which case the type of messages 
// which subscibed to are listed
// -----------------------------------------------------------------------
<'

package te_debug;

type te_port_type: [in_port, out_port];

// Container of method port analysis methods
//    
struct te_port_connections {   
    !all_ports  : list of port_data_s;
    !first_module_index: uint;   // The index of the first module we can use linter access methods
    
    init() is also {
       // The index of the first module which is not compiled (interpreted) and hence has linter acccess support
       first_module_index = rf_manager.get_user_modules().first(not .is_compiled()).get_index();
    };
    !filter: string;
    
    get_data(filter_in: string) : list of data_s is {
        if filter_in == "" {
            filter = "/\/(common|te_debug|TxTE_interface_agent)\//";
        } else {
            filter = filter_in;
        };
         
        all_ports = get_all_ports();    // save for debug
        
        result = all_ports.apply(it.as_a(data_s)); 
    };
    // ------------------------------------------------------------------------
    // get all output ports
    // Get all members whcih are output ports, than find the input ports that are
    // connected to these ports. Results are added to the all_ports list
    // Ports that are not connected to anythinga are ignored
    // ------------------------------------------------------------------------
    get_all_ports(): list of port_data_s is {
        var ports:= rf_manager.get_user_types().all(it is a rf_struct).apply(it.as_a(rf_struct).get_declared_fields())
                                  .all(.get_type() is a rf_method_port and .get_declaration_module().get_full_file_name() !~ filter);
             
        for each (port_rf) in ports {
            if not result.has(.rf == port_rf) {
                // Create the port struct and add to rsult list
                //
                var direction: te_port_type = (port_rf.get_type() is a rf_method_port(p) and p.is_input())? in_port : out_port;
                var new_port: port_data_s = new with {.kind = direction};
                new_port.init_it(port_rf);
                result.add(new_port);
            }; 
        }; // for each (port_rf) in ports
          
        set_port_connections(result);

    }; // get_all_ports()
             
    // ------------------------------------------------------------------------
    // Look for port connection in any conenct_port() methods of any struct.
    // Connection can be:
    //    1. from the router output port to an input port
    //         look for a call to the subscribe() method of the router
    //    2. from any other output port to one of more input ports
    //         look for output port connection to input port i.e x_out_port.connect(y_in_port)
    // ------------------------------------------------------------------------
    set_port_connections(all_ports: list of port_data_s) is {
        // get the RF object of the router subscribe() methods
        var subscribe: rf_method = rf_manager.get_struct_by_name("router_util_u").get_method("subscribe");


        // get all relevant connect_port() methods
        //
        var connect_methods:= rf_manager.get_user_types().all(it is a rf_like_struct).apply(it.as_a(rf_like_struct)) // all struct
                             .apply(.get_layers()).all(.get_module().get_index() > first_module_index)               // all struct/methods extensions
                             .apply(.get_method_layers()).all(.get_defined_entity().get_name() == "connect_ports");  // All extensions to 'connect_ports' methods

        for each (method) in connect_methods {     // for each connect_port methods
        
            // set all connections to the router defined in this method
            //
            set_router_connection_msgs(all_ports, method, subscribe);
            
            // get all feilds accessed in this methods. Note that many connection can be
            // defined within one connect_port methods, hence we look for output port follwed
            // by an input port
            //
            var connected_ports:= lint_manager.get_all_entity_references_in_context(method, {field}) // get all accesses to fields/ports
                                  .all(.get_entity().as_a(rf_field).get_type() is a rf_method_port)
                                  .sort(.get_source_line_num()).apply(.get_entity().as_a(rf_field));
 
            for each (port_rf) in connected_ports {
                if port_rf.get_type() is a rf_method_port (mp) and mp.is_output() {
                    var out_port: port_data_s = all_ports.first(.rf == port_rf);                 // get the out port data struct
                    var idx: uint = index+1;                                                     // index of next method ports
                    if out_port != NULL and idx < connected_ports.size() and                     // out port followed by an input port?
                               connected_ports[idx].get_type() is a rf_method_port (mp) and mp.is_input() {

                        var in_port:  port_data_s = all_ports.first(.rf == connected_ports[idx]);// get the input port data struct
                        out_port.connected_to.add(in_port);                                      // Add the connection to the out port
                        in_port.connected_to.add(out_port);                                      // Add the connection to the in por
                    };
                };
            };  // for each (port_rf)
        };// for each (method)
    }; // set_port_connections()

    // ------------------------------------------------------------------------
    // if 'connect_port()' method is a is calling the router subscribe() method, 
    // looks for the related input port and set its message types list 
    // (indicating it is connected to the router)
    // ------------------------------------------------------------------------
    set_router_connection_msgs(all_ports: list of port_data_s, connect_port_method: rf_method_layer, subscribe: rf_method) is {

        var all_entities: = lint_manager.get_all_entity_references_in_context(connect_port_method, {method;field;enum_item})
                            .apply(.get_entity());
                            

        for each (entity) using index (idx) in all_entities {
            if entity is a rf_method and entity == subscribe {
                var port_index := all_entities.first_index(index > idx      // method port after the subscribe method call
                                  and it is a rf_field (f) and f.get_type() is a rf_method_port);

                var port_rf : rf_field = all_entities[port_index].as_a(rf_field);
                var port:= all_ports.first(.rf == port_rf);

                if port != NULL {   // port my have been filtered out (in common or it is not interpreted)
                    // get all message enum type after the ubscribe method call and before the port parameter
                    //
                    port.router_msgs = all_entities.all(index in [idx..port_index] and it is a rf_enum_item (en)
                            and en.get_defining_type().get_name() == "txte_msg_type_t")
                            .apply(it.get_name().as_a(txte_msg_type_t));
                };

            }; //if entity is a rf_method and entity == subscribe 
        };  
    }; // set_router_connection_msgs()

}; //  te_port_connections



// method ports definition struct
//
struct port_data_s like data_s {
    name          : string;
    rf            : rf_field;                 // The reflection object of the port member, when it is a method port
    struct_rf     : rf_struct;                // The reflection object of the struct conatining this port
    kind          : te_port_type;             // in_port or out_port
    connected_to  : list of port_data_s;       // ports I'm connected to 
    router_msgs   : list of txte_msg_type_t;  // if connected to router, contains the message type it receives

    // A constructor method - sets all the fields members
    //
    init_it(port: rf_field) is {
        rf        = port;
        name      = rf.get_name();
        kind      = (rf.get_type() is a rf_method_port (p) and p.is_output())? out_port : in_port;
        struct_rf = rf.get_declaring_struct();
    };
    
}; // struct port_data_s

'>
