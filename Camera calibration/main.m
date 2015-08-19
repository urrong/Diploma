clear

crossMatrix = @(x) [0 -x(3) x(2); x(3) 0 -x(1); -x(2) x(1) 0];
subplot = @(m,n,p) subtightplot (m, n, p, [0.01 0.01], [0 0], [0 0]);

worldImageNames = dir('world images');
worldImages = {};
for i = 1:numel(worldImageNames)
    if ~worldImageNames(i).isdir
        I = imread(['world images/' worldImageNames(i).name]);
        worldImages = [worldImages, {I}];
    end
end

worldPoints = [0 0 0; 
               1 1 0; 
               2 2 0;
               3 3 0;
               4 4 0;
               5 5 0;
               6 6 0;
               7 7 0;
               0 7 0;
               1 6 0;
               2 5 0;
               3 4 0;
               4 3 0;
               5 2 0;
               6 1 0;
               7 0 0];

DEFINE_IMAGE_POINTS = false;

if DEFINE_IMAGE_POINTS
    %define world points on image
    imagePoints = {};
    for i = 1:4
        imshow(worldImages{i});
        [x, y] = getpts();
        imagePoints = [imagePoints, {[x y]}];
    end
    save('imagePoints.mat', 'imagePoints');
else
    load('imagePoints.mat');
end

load('cameraParams.mat');

%display images
for i = 1:4
    subplot(2, 2, i);
    imshow(worldImages{i});
end

%compute extrinsic matrix
A = cameraParams.IntrinsicMatrix';
externalMatrices = {};

for i = 1:numel(imagePoints)
    P = externalEquationMatrix(worldPoints, imagePoints{i}, A);
    [U, S, V] = svd(P);
    P = reshape(V(:, 9), 4, 3)';
    P = fixExternalMatrix(P);
    externalMatrices = [externalMatrices, {P}];
    %-inv(P(:, 1:3)) * P(:, 4) % camera position in world coordinates
end

%project world coordinates on image
for i = 1:4
    subplot(2, 2, i);
    hold on;
    
    for j = 0:7
        for k = 0:7
            x = A * externalMatrices{i} * [j k 0 1]';
            x = x / x(3);
            y = A * externalMatrices{i} * [j k 3 1]';
            y = y / y(3);
            plot([x(1) y(1)], [x(2) y(2)], 'r');
        end
    end
    
    hold off;
end

DEFINE_TRIANGULATION_POINTS = false;

if DEFINE_TRIANGULATION_POINTS
    triangulationPoints = {};
    figure
    for i = 1:4
        imshow(worldImages{i});
        [x, y] = getpts();
        triangulationPoints = [triangulationPoints, {[x y 1]'}];
    end
    save('triangulationPoints.mat', 'triangulationPoints');
else
    load('triangulationPoints.mat');
end

C = [];
for i = 1:4
    C = [C; crossMatrix(triangulationPoints{i}) * A * externalMatrices{i}];
end

[U, S, V] = svd(C);
p = V(:, 4);
norm([3 3 0 1]' - p / p(4))