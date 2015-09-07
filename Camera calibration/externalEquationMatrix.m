function [P] = externalEquationMatrix(worldPoints, imagePoints, intrinsicMatrix)
    invA = inv(intrinsicMatrix);
    P = zeros(2 * size(worldPoints, 1), 12);
    if size(worldPoints, 1) ~= size(imagePoints, 1)
        error('Different number of world and image points');
    end
    
    for i = 1:size(worldPoints, 1)
        X = [worldPoints(i, :)'; 1]; 
        x = invA * [imagePoints(i, :)'; 1];
        x = x / x(3);
        P(i*2-1:i*2, :) = [zeros(1, 4), -X', X' * x(2); X', zeros(1, 4), -X' * x(1)];
    end
    rank(P)
end