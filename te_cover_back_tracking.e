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
// This file is looking for all who drive value into coverage items
// For that, it also create a call stack of all methods that are defined in interpreted files of this TE
// and create a list of methods and who calls it
// It require the use of port connection information as a list of port_data_s
// -----------------------------------------------------------------------
<'

package te_debug;

struct cover_trace_s {
    !all_methods: list of methods_ref_s;
    !all_ports  : list of port_data_s;
    !first_module_index: uint;   // The index of the first module we can use linter access methods
    
    init() is also {
       // The index of the first module which is not compiled (interpreted) and hence has linter access support
       first_module_index = rf_manager.get_user_modules().first(not .is_compiled()).get_index();
    };

    // ------------------------------------------------------------------------
    // API: get a list of cover items and their field dependency
    // ------------------------------------------------------------------------
    get_cover_items(): list of te_cover_item is {
        // all simple cover items
        var items:= rf_manager.get_user_types().all(it is a rf_struct).apply(it.as_a(rf_struct).get_cover_groups()
                   .apply(.get_all_items().all(it is a rf_simple_cover_item)).apply(it.as_a(rf_simple_cover_item)));

        for each (i) in items {
            var new_item: te_cover_item = new;
            new_item.init_it(i);                  // also creates a list of dependent fields
            result.add(new_item);
        };
        
        
    }; // get_cover_items

    // ------------------------------------------------------------------------
    // API: generate a methods call stack  
    // ------------------------------------------------------------------------
    get_methods_stack() is {
        // all_ports = get_all_ports();
        var filter: string = "/\/(common|target|te_debug)\//";
        var methods:= rf_manager.get_user_types().all(it is a rf_struct).apply(it.as_a(rf_struct).get_declared_methods())
                       .all(.get_declaration_module().get_full_file_name() !~ filter);

        for each (m) in methods {
            var new_method: methods_ref_s = new;
            all_methods.add(new_method);
            new_method.init_it(m, all_methods, all_ports);
        };
    }; // get_methods_stack
    
};

struct te_cover_item like data_s {
    name      : string;
    rf        : rf_simple_cover_item;
    dependents: list of rf_field;
    
    init_it(item_rf: rf_simple_cover_item) is {
        rf      = item_rf;
        name    = rf.get_name();
        
        if rf.get_connected_field() != NULL {          // item that covers struct one fields only (no expression is used)
            dependents.add(rf.get_connected_field());
        } else {                                   //items is defined with an expression - get fileds dependency
           var dependent_fields := lint_manager.get_all_entity_references_in_context(rf.get_declaration(), {field});
           dependents.add(dependent_fields.apply(it.get_entity().as_a(rf_field)));
           // TODO: add lint access to look for methods access by this item definition expression. If is is a methods, trace back teh stack to see 
           // who initiate the access
        };

     };
}; // struct te_cover_item


// data struct 
struct methods_ref_s like data_s {
    name          : string;
    rf            : rf_method;                // The relfection object of this method
    struct_rf     : rf_struct;                // the reflection object of the containing struct
    my_port       : port_data_s;               // The port member, if an input port is connected to this method
    router_msgs : list of txte_msg_type_t;  // if connected to router, contains the message type it receives
    out_port_rf   : list of port_data_s;       // all out ports used by this method
    calls         : list of methods_ref_s;    // The methods called by this method
    called_by     : list of methods_ref_s;    // The methods which calls this methods
    

     // A constructor method - sets all the fields members
     //
     init_it(item_rf: rf_method, all_methods: list of methods_ref_s, all_ports: list of port_data_s) is {
         rf             = item_rf;
         name           = rf.get_name();
         struct_rf      = rf.get_declaring_struct();
         my_port        = all_ports.first(it.name == name and it.struct_rf == struct_rf);
         
         if my_port != NULL {
             router_msgs = my_port.router_msgs;
         };

         // get all methods called by me
         var called_methods:= lint_manager.get_all_entity_references_in_context(rf.get_declaration(), {method});
         for each (m) in called_methods.apply(it.get_entity().as_a(rf_method)) {
             var new_method: methods_ref_s = all_methods.first(.rf == m);
             if new_method == NULL {
                new_method = new;
                all_methods.add(new_method);
                new_method.init_it(m, all_methods, all_ports);
             };

             calls.add(new_method);   // add to list of methods called by me
         };
     }; //init_it ()

};    

'>
