classdef Type_Capacitance < Type
    %Type used to store vertex capacitance information
    methods
        function obj = Type_Capacitance(varargin)
            obj = obj@Type(varargin{:});         
        end
    end
    
    methods (Access = protected)
        function SetSubclass(obj)
            obj.error_msg = "Invalid Capacitance Definition: Capacitance must be defined in terms of state x.";
            syms x
            obj.vars = [x];
        end
    end
end
    
