load('matlab_diag.mat');
I1 = imread('1.jpg');
I2 = imread('2.jpg');

figure;
subplot(1, 2, 1);
imshow(I1)
% [x, y] = getpts()
% imPoints1 = [x y]
subplot(1, 2, 2);
imshow(I2)
% [x, y] = getpts()
% imPoints2 = [x y]
% return

A = cameraParams.IntrinsicMatrix';
invA = inv(A);

% worldPoints = [0 0; 1 0; 2 0; 3 0; 4 0; 5 0; 6 0; 7 0;
%                0 1; 1 1; 2 1; 3 1; 4 1; 5 1; 6 1; 7 1;
%                0 2; 1 2; 2 2; 3 2; 4 2; 5 2; 6 2; 7 2;
% ];

%worldPoints = [0 0; 1 1; 2 2; 3 3; 4 4; 5 5; 6 6; 7 7; 0 7; 1 6; 2 5; 3 4; 4 3; 5 2; 6 1; 7 0];

P1 = [];
P2 = [];

for i = 1:size(worldPoints, 1)
    X = [worldPoints(i, :)'; 0; 1]; 
    
    x1 = invA * [imPoints1(i, :)'; 1];
    x1 = x1 / x1(3);
    P1 = [P1; zeros(1, 4), -X', X' * x1(2); X', zeros(1, 4), -X' * x1(1)];
    
    x2 = invA * [imPoints2(i, :)'; 1];
    x2 = x2 / x2(3);
    P2 = [P2; zeros(1, 4), -X', X' * x2(2); X', zeros(1, 4), -X' * x2(1)];
end


[U, S, V] = svd(P1);
P1 = reshape(V(:, 9), 4, 3)';
P1 = fixRTMatrix(P1);
P1(:, 3) = -P1(:, 3);
C1pos = -inv(P1(:, 1:3)) * P1(:, 4)
P1

[U, S, V] = svd(P2);
P2 = reshape(V(:, 9), 4, 3)';
P2 = fixRTMatrix(P2);
C2pos = -inv(P2(:, 1:3)) * P2(:, 4)
P2

subplot(1, 2, 1);
hold on;
for i = 0:10
    for j = 0:10
        x = A * P1 * [i j 0 1]';
        x = x / x(3);
        y = A * P1 * [i j 5 1]';
        y = y / y(3);
        plot([x(1) y(1)], [x(2) y(2)], 'r');
    end
end
hold off;

subplot(1, 2, 2);
hold on;
for i = 0:10
    for j = 0:10
        x = A * P2 * [i j 0 1]';
        x = x / x(3);
        y = A * P2 * [i j 5 1]';
        y = y / y(3);
        plot([x(1) y(1)], [x(2) y(2)], 'r');
    end
end
hold off;

crossMatrix = @(x) [0 -x(3) x(2); x(3) 0 -x(1); -x(2) x(1) 0];

x1 = [1718 1068 1]';
x2 = [1670 1080 1]';

C = [crossMatrix(x1) * A * P1;
     crossMatrix(x2) * A * P2];
[U, S, V] = svd(C);
p = V(:, 4);
p / p(4)