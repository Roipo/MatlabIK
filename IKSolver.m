classdef IKSolver < matlab.mixin.Copyable
    properties
        l
        w
        theta
        P0
        P
        Rl
        Rg
        O
        G
        X
        nJ
        ee
        J
        ForceStop
        Stop
    end
    properties(SetAccess = private)
        
    end
    methods
        function obj=IKSolver
            obj.nJ = 5;
            obj.l=[5,5,5,5; % joint locations in local coordinates. Root is always at [0,0,0]
                0,0,0,0;
                0,0,0,0;];
            
            obj.w=[0,0,0,0; % joint axis in local coordinates.
                0,0,0,0;
                1,1,1,1;];
            
            obj.theta = [0,0,0,0]'; % initial rotations
            obj.P0=[0,0]';
            obj.X=[5,10,0]'; % target
            obj.Rl=cell(obj.nJ,1);
            obj.Rg=cell(obj.nJ,1);
        end
        function DoIteration(obj)
            theta=obj.theta; %#ok<*PROP>
            w=obj.w;
            l=obj.l;
            P0=obj.P0;
            R=obj.Rl;
            obj.ComputeJointRotationMatrices;
            obj.ComputeJointPositions;
            obj.ComputeJacobian;
            
            % compute Jacobian

            % We want to minimize E(theta)=||FK(theta)-X||^2
            % grad E = J'*(FK(theta)-X)
            % Hess E = J'*J
            % We need to solve Hess E p = -grad E
            % => p = -inv(J'*J)*J*(FK(theta)-X)
            % it so happens that inv(J'*J)*J == pinv(J) and therefore
            obj.O = sum((obj.ee-obj.X).^2);
            obj.G = obj.J'*(obj.ee-obj.X);
            p = -pinv(obj.J)*(obj.ee-obj.X);
            obj.theta=theta+p;
        end
        function ComputeJointRotationMatrices(obj)
            for i=1:obj.nJ-1
                obj.Rl{i} = Rot(obj.theta(i),obj.w(:,i));
            end    
        end
        function ComputeJointPositions(obj)
            % computes the positions of all of the joints and puts them in
            % obj.P.
            Rl=obj.Rl;
            P=zeros(3,obj.nJ);

%             P1=R1*l(:,1);
%             P2=R1*(l(:,1)+R2*l(:,2));
%             P3=R1*(l(:,1)+R2*(l(:,2)+R3*l(:,3)));
%             P4=R1*(l(:,1)+R2*(l(:,2)+R3*(l(:,3)+R4*l(:,4))));
            Ri=eye(3);
            p(:,1) = obj.P0;
            for i=1:obj.nJ-1
                Ri=Ri*Rl{i};
                P(:,i+1) = P(:,i)+Ri*obj.l(:,i);
            end

            obj.ee = P(:,end);  % This is FK(theta)
            obj.P=P;
        end
        function ComputeJacobian(obj)   
            R=obj.Rl;
            w=obj.w;
            l=obj.l;
            obj.J(:,1) = cross(w(:,1),R{1}*(l(:,1)+R{2}*(l(:,2)+R{3}*(l(:,3)+R{4}*l(:,4)))));
            obj.J(:,2) = R{1}*cross(w(:,2),R{2}*(l(:,2)+R{3}*(l(:,3)+R{4}*l(:,4))));
            obj.J(:,3) = R{1}*R{2}*cross(w(:,1),R{3}*(l(:,3)+R{4}*l(:,4)));
            obj.J(:,4) = R{1}*R{2}*R{3}*(cross(w(:,1),R{4}*l(:,4)));
        end
        function StartInteractive(obj)
            % initialize
            obj.Stop=0;
            disp('started')
            i=0;
            while ~obj.Stop
                obj.DoIteration
                if mod(i,1)==0
                    notify(obj,'IterationDone');
                end
            end
            disp('stopped')
        end
        function StopInteractive(obj)
            obj.Stop=1;
        end
        
        function x = Check(obj)
            %%whatever you want to check and send to the base workspace
            %assignin('base', 'x', x);
        end
    end
    events
        IterationDone
    end
end

