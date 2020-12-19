classdef Type < matlab.mixin.Copyable
    %TYPE Summary of this class goes here
    %   Detailed explanation goes here
   
    
    properties  % User can set Val_Str or Val_Sym, the corresponding properties are updated automatically
        Val_Str string = string.empty()
        Val_Sym sym = sym.empty()
    end
    
    properties (SetAccess = protected)
        vars sym = sym.empty % contains list of symbolic variables used in type definition.  This property is set by subclasses, i.e. Type_PowerFlow.vars = [x_t, x_h, u_j]
        
        Val_Func function_handle = function_handle.empty() % Value calculation function 
        Jac_Func function_handle = function_handle.empty() % Jacobian calculation function
        
        Jac_Sym sym = sym.empty() % Symbolic Jacobian
    end
    
    properties (SetAccess = protected, GetAccess = protected)
        error_msg string = string.empty
    end
    
    methods
        function obj = Type(type)
            obj.SetSubclass();
            
            if nargin == 1
                if isa(type,'string') || isa(type,'char')
                    obj.Val_Str = type;
                elseif isa(type,'sym')
                    obj.Val_Sym = type;
                else
                    error('Type object must be defined as a string or sym variable.')
                end
            else
                error('Type object must be defined at object creation. Pass the object expression as a string or symbolic expression.')
            end
        end
        
        
        % set the string value and update the symbolic definition
        function set.Val_Str(obj, val) 
            obj.Val_Str = val;
            obj.updateSym();
            init(obj);
        end
        
        % set the symbolic value and update the string definition
        function set.Val_Sym(obj, val)
            obj.Val_Sym = val;
            obj.updateStr();
            init(obj);
        end
        
        function init(obj)            
            % list of all symbolic variables
            T_var_all = symvar(obj.Val_Sym).';
           
            % check to see if T_var is a subset of variable options
            if all(ismember(T_var_all,obj.vars))
                obj.Val_Func = matlabFunction(obj.Val_Sym,'Vars',obj.vars);
                obj.Jac_Sym  = jacobian(obj.Val_Sym,obj.vars);
                obj.Jac_Func = matlabFunction(obj.Jac_Sym,'Vars',obj.vars);
            else
                error(obj.error_msg)
            end
        end
        
        % update the type value property that was not defined
        function updateSym(obj)
            symval = str2sym(obj.Val_Str);
            if isempty(obj.Val_Sym) || obj.Val_Sym ~= symval
                obj.Val_Sym = symval;
            end
        end
        function updateStr(obj)
            strval = string(obj.Val_Sym);
            if isempty(obj.Val_Str) || not(strcmp(obj.Val_Str,strval))
                obj.Val_Str = strval;
            end
        end
        
                
        function val = calcVal(obj, vars_) % Calculates type value with symbolic 'vars' substituted with numeric 'vars_'
        end
        
        function jac = calcJac(obj, vars_) % Calculates type Jacobian with symbolic 'vars' substituted with numeric 'vars_'
        end
        
    end
    
    methods (Access = protected)
        function SetSubclass(obj)
            % Placeholder - Method overriden by subclass
        end
    end
end

