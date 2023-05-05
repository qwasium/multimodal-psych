classdef litedot
    %LITEDOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        posX = 15;
        posY = 15;
        diam = 10;
    end
    
    methods
        function obj = litedot(litdot, posX, posY, dia)
            %LITEDOT Construct an instance of this class
            %   Detailed explanation goes here

            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

