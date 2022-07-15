<'
	struct method_parameter {
    	!param: rf_parameter;
        !has_txte_base_type: bool;
        
        static from_rf_param(rf_param: rf_parameter): method_parameter is {
            result = new with {
                .param = rf_param;
                .has_txte_base_type = rf_param.get_type().get_name() == constants::TXTE_BASE_CLASS_NAME;
            };
        };
        
        to_xml(indent: string = "")  : list of string is {
            result.add(append(indent, "<parameter" ," name=", quote(param.get_name()), " type=", quote(append(param.get_type().get_name())), " has_txte_base_type=", quote(append(has_txte_base_type)), "/>"));
        };
	};
'>
