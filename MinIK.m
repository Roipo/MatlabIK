l=[5,5,5,5; % joint locations in local coordinates. Root is always at [0,0,0]
    0,0,0,0;
    0,0,0,0;]; 

w=[0,0,0,0; % joint axis in local coordinates.
    0,0,0,0;
    1,1,1,1;];

theta = [0,0,0,0]'; % initial rotations
P0=[0,0];
X=[5,10,0]'; % target
h=figure;
axis([-20,20,-20,20]);
pl = line('Marker','.');

while 1
    while 1
        % compute joint locations
        R1=Rot(theta(1),w(:,1));
        R2=Rot(theta(2),w(:,2));
        R3=Rot(theta(3),w(:,3));
        R4=Rot(theta(4),w(:,4));
        
        P1=R1*l(:,1);
        P2=R1*(l(:,1)+R2*l(:,2));
        P3=R1*(l(:,1)+R2*(l(:,2)+R3*l(:,3)));
        P4=R1*(l(:,1)+R2*(l(:,2)+R3*(l(:,3)+R4*l(:,4))));
        FK = P4;  % This is FK(theta)
                
        pl.XData = [P0(1),P1(1),P2(1),P3(1),P4(1)];
        pl.YData = [P0(2),P1(2),P2(2),P3(2),P4(2)];
        drawnow;

        % compute Jacobian
        J=zeros(3,4);
        J(:,1) = cross(w(:,1),R1*(l(:,1)+R2*(l(:,2)+R3*(l(:,3)+R4*l(:,4)))));
        J(:,2) = R1*cross(w(:,2),R2*(l(:,2)+R3*(l(:,3)+R4*l(:,4))));
        J(:,3) = R1*R2*cross(w(:,1),R3*(l(:,3)+R4*l(:,4)));
        J(:,4) = R1*R2*R3*(cross(w(:,1),R4*l(:,4)));
        
        % We want to minimize E(theta)=||FK(theta)-X||^2
        % grad E = J'*(FK(theta)-X)
        % Hess E = J'*J
        % We need to solve Hess E p = -grad E
        % => p = -inv(J'*J)*J*(FK(theta)-X)
        % it so happens that inv(J'*J)*J == pinv(J) and therefore
        p = -pinv(J)*(FK-X);
        if norm(p)<=0.0001
            break
        end
        theta=theta+p;
    end
   [Xc,Yc] = ginput(1);
   X=[Xc,Yc,0]'; % target
end

function R = Rot(alpha, w)
    w = w(:);
    w = w./sqrt(w'*w);
    ucross = [0, -w(3) w(2); w(3), 0, -w(1); -w(2), w(1), 0];
    R = cos(alpha)*eye(3) + sin(alpha)*ucross + (1-cos(alpha))*(w*w');
end
