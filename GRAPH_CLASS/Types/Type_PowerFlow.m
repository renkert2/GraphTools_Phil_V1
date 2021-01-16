classdef Type_PowerFlow < Type
    %Type used to store power flow information
    
    properties (SetAccess = private)
        num_inputs {mustBeInteger, mustBeNonnegative} = 0
    end
    
    methods
        function obj = Type_PowerFlow(type)
            [vars_temp, params_temp, num_inputs_temp] = Type_PowerFlow.parsePowerFlowVars(type);
            obj = obj@Type(vars_temp, params_temp, type);
            
            obj.num_inputs = num_inputs_temp;
        end
        
        
        function val = calcVal(obj, xt, xh, u) % Calculates type value with symbolic 'vars' substituted with numeric 'vars_'
            num_args = nargin-1; % Matlab counts obj as an input arguments
            num_inputs_array = [obj.num_inputs];
            if num_args == 3 && ~isempty(u)
                if isvector(u)
                    if iscolumn(u)
                        u = u'; % Vector of inputs u must be a row vector
                    end
                end
                if any(num_inputs_array)
                    assert(length(u) >= max(num_inputs_array), 'Invalid number of inputs. Number of columns of u must be greater than or equal to the maximum number of inputs');
                    val = calcVal@Type(obj, xt, xh, u);
                else
                    val = calcVal@Type(obj,xt,xh);
                end
            elseif num_args == 2 || isempty(u)
                assert(all(num_inputs_array == 0), "Input argument 'u' required'");
                val = calcVal@Type(obj, xt, xh);
            else
                error("Invalid arguments")
            end
        end
    
        function val = calcJac(obj, xt, xh, u) % Calculates type Jacobian with symbolic 'vars' substituted with numeric 'vars_'
            num_args = nargin-1; % Matlab counts obj as an input arguments
            num_inputs_array = [obj.num_inputs];
            if num_args == 3 && ~isempty(u)
                if isvector(u)
                    if iscolumn(u)
                        u = u'; % Vector of inputs u must be a row vector
                    end
                else
                    error('u must be a vector of inputs')
                end
                if any(num_inputs_array)
                    assert(length(u) >= max(num_inputs_array), 'Invalid number of inputs. Number of columns of u must be greater than or equal to the maximum number of inputs');
                    val = calcJac@Type(obj, xt, xh, u);
                else
                    val = calcJac@Type(obj,xt,xh);
                end
            elseif num_args == 2 || isempty(u)
                assert(all(num_inputs_array == 0), "Input argument 'u' required'");
                val = calcJac@Type(obj, xt, xh);
            else
                error("Invalid arguments")
            end
        end
    
    
    function updateInputs(obj, type)
    [vars_temp, params_temp, num_inputs_temp] = Type_PowerFlow.parsePowerFlowVars(type);
    obj.vars = vars_temp;
    obj.params = params_temp;
    obj.num_inputs = num_inputs_temp;
    end
    
    function init(obj, type)
    obj.updateInputs(type)
    init@Type(obj, type);
    end
    
    
end

methods(Static)
    function [vars, params, num_inputs] = parsePowerFlowVars(type)
        num_inputs = countInputVars(type);
        [vars, params] = calcVars(num_inputs);
        
        function num_inputs = countInputVars(type)
            if isa(type, 'sym') || isa(type, 'char')
                type = string(type);
            end
            
            assert(isa(type, 'string'), "PowerFlow Type must be of type string, char, or sym");
            
            patt_list = '(?<=u)\d+';
            input_list = double(regexp(type, patt_list, 'match')); % Finds 'u[12...N]' occurences in expression
            input_list_flag = not(isempty(input_list));
            
            patt_single_input = 'u(?!\d)'; % Finds 'u' occurences in expression
            single_input_flag = not(isempty(regexp(type, patt_single_input, 'start')));
            
            if input_list_flag && ~single_input_flag
                num_inputs = max(input_list);
            elseif max(input_list)==1
                num_inputs = 1;
            elseif ~single_input_flag && ~input_list_flag
                num_inputs = 0;
            else
                error("PowerFlow Type Definition must contain indexed inputs 'u1,u2,...'");
            end
        end
        
        function [vars, params] = calcVars(num_inputs)
            state_vars = [sym('xt'), sym('xh')];
            if num_inputs >= 1
                input_vars =sym('u', [1, max(num_inputs,2)]);
                vars = [state_vars, input_vars];
                params = {state_vars(1), state_vars(2), input_vars};
            elseif num_inputs == 0
                vars = state_vars;
                params = {state_vars(1), state_vars(2)};
            end
        end
    end
    
end
end

