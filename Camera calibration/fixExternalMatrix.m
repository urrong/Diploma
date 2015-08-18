function [P] = fixExternalMatrix(P)
    P = P / norm(P(:,1));
%     a = P(:, 1);
%     b = P(:, 2);
%     k = -0.5 * a' * b; %approximation
%     P(:, 1) = a + k * b;
%     P(:, 2) = b + k * a;
%     P = P / norm(P(:,1));
%     P(:, 2) = P(:, 2) / norm(P(:, 2));
    P(:, 3) = cross(P(:, 1), P(:, 2));
end