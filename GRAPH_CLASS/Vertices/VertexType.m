classdef VertexType
    %VERTEXTYPE Summary of this class goes here
    %   Detailed explanation goes here
    enumeration
        % Domains derived from: https://www.mathworks.com/help/physmod/simscape/ug/basic-principles-of-modeling-physical-networks.html#bq89sba-3
        Abstract ('Abstract', 'Abstract')
        
        % Electrical Domain
        Voltage ('Electrical','Effort')
        Current ('Electrical','Flow')
        
        % Hydraulic Domain
        GaugePressure ('Hydraulic','Effort')
        VolumetricFlowRate ('Hydraulic','Flow')
        
        % Isothermal Liquid
        AbsolutePressure ('IsothermalLiquid','Effort')
        MassFlowRate ('IsothermalLiquid','Flow')
        
        % Magnetic Domain
        MagnetomotiveForce ('Magnetic','Effort')
        Flux ('Magnetic','Flow')
        
        % Mechanical Rotational Domain
        AngularVelocity ('MechanicalRotational','Effort')
        Torque ('MechanicalRotational','Flow')
        
        % Mechanical Translational Domain
        TranslationalVelocity ('MechanicalTranslational','Effort')
        Force ('MechanicalTranslational','Flow')
        
        % Thermal Domain
        Temperature ('Thermal','Effort')
        HeatFlow ('Thermal','Flow')
    end
    
    properties
        Domain Domain = 'Abstract'
        VariableType VariableType = 'Abstract'
    end
    
    methods
        function obj = VertexType(domain, var_type)
            obj.Domain = domain;
            obj.VariableType = var_type;
        end
        
        function x = isAbstract(obj)
            x = obj.VariableType == VariableType.Abstract;
        end
        
        function x = isEffort(obj)
            x = obj.VariableType == VariableType.Effort;
        end
        
        function x = isFlow(obj)
            x = obj.VariableType == VariableType.Flow;
        end
        
        function x = isCompatible(obj1, obj2)
            if (obj1.Domain == Domain.Abstract || obj2.Domain == Domain.Abstract)
                x = true;
            elseif (obj1.VariableType ~= obj2.VariableType) && (obj1.Domain == obj2.Domain)
                x = true;
            else
                x = false;
            end
        end
    end
        
end

