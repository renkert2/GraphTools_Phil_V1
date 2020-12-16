classdef SplitJunction < Component
    % SplitJunction is a class the defines a fluid split or junction model
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Author: Christopher T. Aksland
    % Association: University of Illionis at Urbana-Champaign
    % Contact: aksland2@illinois.edu
    % Revision History:
    % 7/6/2020 - Class creation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
        
        % Block Name
        Name char ='Split Junction'
        % Working Fluid
        fluid char = 'JP8'
        % Initial Fluid temperature [C]
        T_init(1,1) double {mustBeNumeric} = 25;
        % Fluid Specific Heat [J/kg]
        cp_f (1,1) double {mustBeNumeric} = 2000;
        % Number of inflows 
        n_in(1,1) double {mustBeInteger} = 1;
        % Number of outflows 
        n_out(1,1) double {mustBeInteger} = 1;
    end
    
    methods
        function obj = SplitJunction(varargin)          
            obj@Component(varargin{:}); % calls the superclass constructor           
        end
    end
    
    methods (Access = protected)
        function g = DefineGraph(obj)
            % edge matrix
            E = [[(2:obj.n_in+1)',ones(obj.n_in,1)]; ...
                                [ones(obj.n_out,1),(obj.n_in+2:obj.n_in+obj.n_out+1)']];
             
            % Capacitance Types
            C(1) = Type_Capacitance('Val_Char',"1");  
               
            % Power Flow Types
            P(1) = Type_PowerFlow('Val_Char',"u1*xt");
            
            % define vertices
            Vertex(1) = GraphVertex_Internal('Description','Junction Temp','Type',1,'Capacitance',C(1),'Capacitance',C(1));
            for i = 1:obj.n_in
                Vertex(i+1) = GraphVertex_External('Description',['Inlet' num2str(i)],'Capacitance',C(1));
            end      
            for i = obj.n_in+1:obj.n_in+obj.n_out
                Vertex(i+1) = GraphVertex_External('Description',['Outlet' num2str(i-obj.n_in)],'Capacitance',C(1));
            end 
            
            % define edges
            for i = 1:obj.n_in+obj.n_out
                Edge(i) = GraphEdge_Internal('PowerFlow',P(1),'Input',i,'Port',i,'Coefficient',obj.cp_f);
            end
                        
            g = Graph(E,Vertex,Edge);
            
        end
    end
end