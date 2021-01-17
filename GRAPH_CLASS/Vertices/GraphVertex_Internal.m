classdef GraphVertex_Internal < GraphVertex
    %GRAPHVERTEX_INTERNAL Summary of this class goes here
    %   Detailed explanation goes here  
    properties
        CapFunction (1,1) LookupFunction
    end
    
    methods
        function obj = GraphVertex_Internal(varargin) % constructor method
            obj@GraphVertex(varargin{:}); % calls the superclass constructor
        end       
    end
end

