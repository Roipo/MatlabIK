function R = Rot(alpha, w)
    w = w(:);
    w = w./sqrt(w'*w);
    ucross = [0, -w(3) w(2); w(3), 0, -w(1); -w(2), w(1), 0];
    R = cos(alpha)*eye(3) + sin(alpha)*ucross + (1-cos(alpha))*(w*w');
end