clear

crossMatrix = @(x) [0 -x(3) x(2); x(3) 0 -x(1); -x(2) x(1) 0];
subplot = @(m,n,p) subtightplot (m, n, p, [0.06 0.02], [0.05 0.05], [0.02 0.02]);

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
    imwrite(worldImages{i}, ['camera', int2str(i), '0.jpg'])
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
end

for i = 1:3
    externalMatrices{i}(:, 3) = -externalMatrices{i}(:, 3);
end

for i = 1:numel(intrinsicParams)
    params(i) = struct('intrinsic', intrinsicParams{i}.IntrinsicMatrix', ...
                       'extrinsic', externalMatrices{i}, ...
                       'radial', intrinsicParams{i}.RadialDistortion);
end

save('variables/cameraParams_py.mat', 'params')
figure
%reprojeciton error
for i = 1:numel(worldImages)
    e = [];
    for j = 1:size(worldPoints, 1)
        x = intrinsicParams{i}.IntrinsicMatrix' * externalMatrices{i} * [worldPoints(j, :) 1]';
        x = x / x(3);
        e = [e norm(x(1:2) - imagePoints{i}(j, :)')];
    end
    m = sum(e) / numel(e)
    sum((e - m) .^ 2) / numel(e)
    %bar plotting
    subplot(4, 1, i);
    edges = linspace(0, 2.1, 22);
    bar(histc(e, edges));
    title(['Kamera ' num2str(i)], 'FontSize', 18)
    ylim([0 5])
    xlim([0 21])
    set(gca,'FontSize', 18)
    set(gca,'XTick', 0:21);
    set(gca,'XTickLabel',edges );
    set(gca,'YTick', 0:5);
    set(gca,'YTickLabel', 0:5)
end

return
figure(1)
%project world coordinates on image
for i = 1:numel(worldImages)
    subplot(2, 2, i);
    hold on;
    
    for j = 20 * (-3:12)
        for k = 20 * (0:3)
            x = intrinsicParams{i}.IntrinsicMatrix' * externalMatrices{i} * [j k 0 1]';
            x = x / x(3);
            %y = intrinsicParams{i}.IntrinsicMatrix' * externalMatrices{i} * [5*20 1.5*20 100 1]';
            y = intrinsicParams{i}.IntrinsicMatrix' * externalMatrices{i} * [80 30 100 1]';
            y = y / y(3);
            plot([x(1) y(1)], [x(2) y(2)], 'r');
        end
    end
    
    hold off;
end

return
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

%triangulationPoints{1} = triangulationPoints{1} + [2 -2 0]';
triangulationPoints{1} = [442 208 1]';
triangulationPoints{2} = [437 143 1]';

subplot(2, 2, 1)
hold on
plot(triangulationPoints{1}(1), triangulationPoints{1}(2), 'gx')
hold off
subplot(2, 2, 2)
hold on
plot(triangulationPoints{2}(1), triangulationPoints{2}(2), 'gx')
hold off

orig = triangulationPoints{1};
n = 0;
R = zeros(2*n+1, 2*n+1);

for xx = -n:n
    for yy = -n:n
        triangulationPoints{1} = orig + [xx; yy; 0];
        C = [];
        for i = 1:2
            C = [C; crossMatrix(triangulationPoints{i}) * intrinsicParams{i}.IntrinsicMatrix' * externalMatrices{i}];
        end
        [U, S, V] = svd(C);
        p = V(:, 4);
        p = p / p(4)
        norm(p)
        R(xx+n+1, yy+n+1) = norm([20 0 0 1]' - p)
    end
end
sum(R(:)) / numel(R)
