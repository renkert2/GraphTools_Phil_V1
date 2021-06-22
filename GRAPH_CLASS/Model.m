classdef Model < matlab.mixin.Copyable
    % The Model class in the Graph Modeling Toolbox is used to generically
    % define a model in nonlinear state space form.
    %
    % System Description
    % x_dot = f_sym(x,u,d)
    % y     = g_sym(x,u,d)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Contributors: Christopher T. Aksland and Phil Renkert
    % Association: University of Illionis at Urbana-Champaign
    % Contact: aksland2@illinois.edu and renkert2@illinois.edu
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % potential improvements:
    % Add Constructor
    % Find better solution than splitapply() for calcX
    % VPA all the things
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
        Nx (1,1) double = 0 % number of states
        Nu (1,1) double = 0 % number of inputs
        Nd (1,1) double = 0 % number of disturbances
        Ny (1,1) double = 0 % number of outputs
        
        StateDescriptions (:,1) string
        InputDescriptions (:,1) string
        DisturbanceDescriptions (:,1) string
        OutputDescriptions (:,1) string
        
        SymVars SymVars {mustBeScalarOrEmpty} % Contains fields x,u,d, each an array of symbolic variables
        Params compParam
    end
    
    properties
        f_sym (:,1) sym % f(x,u,d), can contain symbolic parameters
        g_sym (:,1) sym % g(x,u,d), can contain symbolic parameters
    end
    
    properties (SetAccess = protected, GetAccess = protected)
        f_func function_handle {mustBeScalarOrEmpty} % calculates x_dot
        g_func function_handle {mustBeScalarOrEmpty} % calculates y
    end
    
    properties (Dependent)
        StateTable table
        InputTable table
        DisturbanceTable table
        OutputTable table
    end
    
    methods
        function init(obj)
            if isempty(obj.SymVars)
                setSymVars(obj);
            end
            setCalcFuncs(obj);
        end
        
        function setSymVars(obj)
            obj.SymVars = SymVars('Nx', obj.Nx, 'Nd', obj.Nd, 'Nu', obj.Nu);
        end
        
        function setCalcFuncs(obj)
            f = obj.f_sym;
            g = obj.g_sym;
            
            CalcFuncs_Cell = genMatlabFunctions(obj, {f, g});
            obj.f_func = CalcFuncs_Cell{1};
            obj.g_func = CalcFuncs_Cell{2};
        end
        
        function F = CalcF(obj,x,u,d)
            param_lengths = [obj.Nx, obj.Nu, obj.Nd];
            
            vars = {x,u,d};
            
            for i = 1:numel(vars)
                assert(size(vars{i},1) >= param_lengths(i), "Argument %d requires %d entries", i, param_lengths(i));
            end
            
            F = obj.CalcX(obj.f_func, vars);
        end
        
        function G = CalcG(obj,x,u,d)
            param_lengths = [obj.Nx, obj.Nu, obj.Nd];

            vars = {x,u,d};
            
            for i = 1:numel(vars)
                assert(size(vars{i},1) >= param_lengths(i), "Argument %d requires %d entries", i, param_lengths(i));
            end
            
            G = obj.CalcX(obj.g_func, vars);
        end
        
        function [x_bar,y_bar] = calcSteadyState(obj, u, d, x0, opts)
            % Solves CalcF == 0 to get the steady state values
            arguments
                obj
                u double
                d double
                x0 double = []
                opts.SolverOpts struct = optimset('Display', 'off');
            end
            
            if isempty(x0)
                x0 = zeros(obj.Nx,1);
            end
            [x_bar,] = fsolve(@(x) CalcF(obj,x,u,d), x0, opts.SolverOpts);
            
            if nargout == 2
                y_bar = CalcG(obj,x_bar,u,d);
            end
        end
                   
        function lm = getLinearModel(obj)
            f = obj.f_sym;
            g = obj.g_sym;
            
            x = obj.SymVars.x;
            u = obj.SymVars.u;
            d = obj.SymVars.d;
     
            A = jacobian(f,x);
            B = jacobian(f,u);
            E = jacobian(f,d);
            
            C = jacobian(g,x);
            D = jacobian(g,u);
            H = jacobian(g,d);
            
            f0 = subs(obj.f_sym, vertcat(x,u,d), zeros(obj.Nx + obj.Nu + obj.Nd,1));
            g0 = subs(obj.g_sym, vertcat(x,u,d), zeros(obj.Nx + obj.Nu + obj.Nd,1));
            
            %lm = LinearModel(A,B,E,C,D,H);
            lm = LinearModel();
            copyModelProps(obj, lm);
            
            [lm.A_sym, lm.B_sym, lm.E_sym, lm.C_sym, lm.D_sym, lm.H_sym, lm.f0_sym, lm.g0_sym]...
                = deal(A,B,E,C,D,H,f0,g0);
            
            lm.init();
        end
        
        function h = makeSimulinkModel(obj, name)
            if nargin == 1
                name = 'Model_Simulink';
            end
            
            try
                h = new_system(name, 'FromFile', 'Model_SimulinkTemplate');
            catch
                h = load_system(name);
            end
            
            obj_name = [name '__OBJECT'];
            assignin('base', obj_name, obj);
            
            set_param([name '/Model'], 'x_0', mat2str(zeros(obj.Nx,1)));
            
            set_param([name '/Model/Model_CalcF'], 'MATLABFcn', ['@(x) CalcMux(' obj_name ',x,@CalcF)']);
            set_param([name '/Model/Model_CalcF'], 'OutputDimensions', mat2str([obj.Nx]));
            set_param([name '/Model/Model_CalcG'], 'MATLABFcn', ['@(x) CalcMux(' obj_name ',x,@CalcG)']);
            set_param([name '/Model/Model_CalcG'], 'OutputDimensions', mat2str([obj.Ny]));
            
            if obj.Nu
                set_param([name '/Model/Input1'], 'PortDimensions', mat2str([obj.Nu,1]));
            end
            if obj.Nd
                set_param([name '/Model/Input2'], 'PortDimensions', mat2str([obj.Nd,1]));
            end
        end
        
        function t = get.StateTable(obj)
            state_syms = arrayfun(@(x) string(x), obj.SymVars.x);
            t = table(state_syms, obj.StateDescriptions, 'VariableNames', ["State Variable", "Description"]);
        end
        
        function t = get.InputTable(obj)
            in_syms = arrayfun(@(x) string(x), obj.SymVars.u);
            t = table(in_syms, obj.InputDescriptions,'VariableNames', ["Input Variable", "Description"]);
        end
        
        function t = get.DisturbanceTable(obj)
            dist_syms = arrayfun(@(x) string(x), obj.SymVars.d);
            t = table(dist_syms, obj.DisturbanceDescriptions, 'VariableNames', ["Disturbance Variable", "Description"]);
        end
        
        function t = get.OutputTable(obj)
            out_syms = arrayfun(@(x) sprintf("y%d", x), 1:obj.Ny);
            t = table(out_syms', obj.OutputDescriptions);
        end
        
        function c = parseMuxArg(obj, mux_arg)
            c = cell(1,3);
            start_indices = 1 + cumsum([0 obj.Nx obj.Nu]);
            end_indices = cumsum([obj.Nx obj.Nu obj.Nd]);
            c{1} = mux_arg(start_indices(1):end_indices(1));
            c{2} = mux_arg(start_indices(2):end_indices(2));
            c{3} = mux_arg(start_indices(3):end_indices(3));
        end
        
        function v = CalcFMux(obj, mux_arg)
           c = parseMuxArg(obj, mux_arg);
           v = CalcF(obj, c{:});
        end
                
        function v = CalcGMux(obj, mux_arg)
           c = parseMuxArg(obj, mux_arg);
           v = CalcG(obj, c{:});
        end
    end
   
    methods (Access = protected)
        function funcs = genMatlabFunctions(obj, syms, vars)
            % Generates matlabFunctions from symbolic arrays
            % i.e. f_sym -> calcF_Func and g_sym -> calcG_Func in
            % setCalcFuncs().
            % Vars argument is optional
            arguments 
                obj
                syms
                vars = {}
            end
            
            if isempty(vars)
                vars = {[obj.SymVars.x], [obj.SymVars.u], [obj.SymVars.d]};
            end
            
            cell_flag = isa(syms, 'cell');
            if cell_flag
                funcs = cellfun(@processSym, syms, 'UniformOutput', false);
            else
                funcs = processSym(syms);
            end
            
            function func = processSym(sym)
                if isa(sym, 'sym')
                    if ~isempty(obj.Params)
                        func = matlabFunction(obj.Params, sym, vars);
                    else
                        func = matlabFunction(sym,'Vars',vars);
                    end
                else
                    func = @(varargin) sym;
                end
            end
        end
        
        function copyModelProps(obj_from, obj_to, opts)
            arguments
                obj_from
                obj_to
                opts.Properties = ["Nx","Nu","Nd","Ny",...
                "StateDescriptions", "InputDescriptions", "DisturbanceDescriptions", "OutputDescriptions",...
                "SymVars","Params"];
            end

            for prop = opts.Properties
                obj_to.(prop) = obj_from.(prop);
            end
        end
    end
    
    methods (Static, Access = protected)
        function X = CalcX(func, vars)
            % Wrapper for matlabFunction properties, does error checking
            % and assists with vectorizing the function
            
            n_ins = nargin(func);
            if n_ins > -1
                assert(numel(vars) == n_ins, "Func Requires %d Arguments", n_ins);
            end
            
            if size(vars{1},2) == 1
                X = func(vars{:});
            else
                X = splitapply(func,vars{:},1:size(vars{1},2));
            end
        end
    end
end

