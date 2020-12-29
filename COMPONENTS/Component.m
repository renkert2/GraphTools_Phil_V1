classdef Component < matlab.mixin.Heterogeneous & handle
    %COMPONENT Super class to be inherited by Components (i.e.
    %Battery, Motor, Heat Exchanger, etc...
    %   Detailed explanation goes here
    
    properties %(SetAccess = protected)
        Name string = "Component"
        graph Graph = Graph.empty()
    end
    
    methods
        function obj = Component(varargin)
            if nargin > 1
                my_inputparser(obj,varargin{:}); % input parser component models
            end
            obj.init(); % I don't know why we need this and can't just call ConstructGraph - CTA
        end
        
        function set.Name(obj, name)
            obj.Name = string(name);
        end
        
        function init(obj)
            obj.ConstructGraph();
            obj.DefineChildren();
        end
    end
    
    methods (Access = protected)
        function ConstructGraph(obj)
            g = DefineGraph(obj);
            obj.graph = g;
        end
        
        function g = DefineGraph(p)
            g = Graph(); % Function to be defined by child classes
        end
        
        function DefineChildren(obj)
            try
                for i = 1:numel(obj.graph.Inputs)
                    obj.graph.Inputs(i).Parent = obj;
                end
            end
        end
    end
    
    
end

