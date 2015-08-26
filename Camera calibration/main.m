clear

crossMatrix = @(x) [0 -x(3) x(2); x(3) 0 -x(1); -x(2) x(1) 0];
subplot = @(m,n,p) subtightplot (m, n, p, [0.01 0.01], [0 0], [0 0]);

worldImageNames = dir('camera images');
worldImages = {};
for i = 1:numel(worldImageNames)
    if ~worldImageNames(i).isdir
        I = imread(['camera images/' worldImageNames(i).name]);
        worldImages = [worldImages, {I}];
    end
end

load('variables/intrinsicParams.mat');
for i = 1:numel(worldImages)
    worldImages{i} = undistortImage(worldImages{i}, intrinsicParams{i});
end

worldPoints = [(12:-2:-2)' ones(8, 1)*0 zeros(8, 1);
               (12:-2:-2)' ones(8, 1)*3 zeros(8, 1)];
worldPoints = worldPoints * 20;

DEFINE_IMAGE_POINTS = false;

if DEFINE_IMAGE_POINTS
    %define world points on image
    imagePoints = {};
    for i = 1:numel(worldImages)
        imshow(worldImages{i});
        [x, y] = getpts();
        imagePoints = [imagePoints, {[x y]}];
    end
    save('variables/imagePoints.mat', 'imagePoints');
else
    load('variables/imagePoints.mat');
end

%display images
for i = 1:numel(worldImages)
    subplot(2, 2, i);
    imshow(worldImages{i});
end

%compute extrinsic matrix
externalMatrices = {};

for i = 1:numel(imagePoints)
    P = externalEquationMatrix(worldPoints, imagePoints{i}, intrinsicParams{i}.IntrinsicMatrix');
    [U, S, V] = svd(P);
    P = reshape(V(:, 9), 4, 3)';
    P = fixExternalMatrix(P);
    externalMatrices = [externalMatrices, {P}];
    
%    [rotationMatrix,translationVector] = extrinsics(imagePoints{i}, worldPoints(:, 1:2), intrinsicParams{i});
%    externalMatrices{i} = [rotationMatrix' translationVector'];
%     
%    -inv(P(:, 1:3)) * P(:, 4) % camera position in world coordinates
end

for i = 2:3
    externalMatrices{i}(:, 3) = -externalMatrices{i}(:, 3);
end

for i = 1:numel(intrinsicParams)
    params(i) = struct('intrinsic', intrinsicParams{i}.IntrinsicMatrix', ...
                       'extrinsic', externalMatrices{i}, ...
                       'radial', intrinsicParams{i}.RadialDistortion);
end

save('variables/cameraParams_py.mat', 'params')

figure(1)
%project world coordinates on image
for i = 1:numel(worldImages)
    subplot(2, 2, i);
    hold on;
    
    for j = 20 * (-3:12)
        for k = 20 * (0:3)
            x = intrinsicParams{i}.IntrinsicMatrix' * externalMatrices{i} * [j k 0 1]';
            x = x / x(3);
            y = intrinsicParams{i}.IntrinsicMatrix' * externalMatrices{i} * [5*20 1.5*20 100 1]';
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
    save('variables/triangulationPoints.mat', 'triangulationPoints');
else
    load('variables/triangulationPoints.mat');
end

C = [];
for i = 1:4
    C = [C; crossMatrix(triangulationPoints{i}) * intrinsicParams{i}.IntrinsicMatrix' * externalMatrices{i}];
end

[U, S, V] = svd(C);
p = V(:, 4);
p = p / p(4)
norm([20 0 0 1]' - p)