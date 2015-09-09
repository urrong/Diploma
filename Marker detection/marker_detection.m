READ = false;

if READ
    markerImageNames = dir('marker images');
    markerImages = {};
    for i = 1:numel(markerImageNames)
        if ~markerImageNames(i).isdir
            I = imread(['marker images/' markerImageNames(i).name]);
            I(1:20, :, :) = 0;
            markerImages = [markerImages, {I}];
        end
    end
    return
    centers = {};
    for i = 1:numel(markerImages)
        imshow(markerImages{i})
        set(gcf,'units','normalized','outerposition',[0 0 1 1])
        [x, y] = getpts();
        centers = [centers, [x, y]];
    end
    save('centers.mat', 'centers');
end
load('centers.mat')

% minimum = [240, 240, 0];
% maximum = [255, 255, 200];

minimum = [200, 200, 0];
maximum = [255, 255, 180];

minimum2 = [200, 200, 0];
maximum2 = [255, 255, 230];

errors = [];
s = 0.5;
n = 0;
for i = 1:numel(markerImages)
    I = imresize(markerImages{i}, s);
    
    I1 = I(:,:,1) >= minimum(1) & I(:,:,1) <= maximum(1);
    I2 = I(:,:,2) >= minimum(2) & I(:,:,2) <= maximum(2);
    I3 = I(:,:,3) >= minimum(3) & I(:,:,3) <= maximum(3);
    I_T = I1 & I2 & I3;
    
    I(:,:,1) = I(:,:,1) + uint8(I_T * 255);
    I(:,:,2:3) = I(:,:,2:3) .* uint8(~repmat(I_T * 255, 1, 1, 2)); 
    
    A = sum(I_T(:));
    if A == 0
        continue;
    end
    n = n + 1;
    [r, c] = find(I_T);
    x = sum(c) / A / s;
    y = sum(r) / A / s;
    
    if norm([x y] - centers{i}) > 5
        n = n - 1;
        continue;
    end
    
    errors = [errors, norm([x y] - centers{i})];
    
%     imshow(markerImages{i})
%     set(gcf,'units','normalized','outerposition',[0 0 1 1])
%     hold on
%     plot(x, y, 'g+', 'MarkerSize', 10, 'LineWidth', 1);
%     hold off
%     pause(0.1)
    
    continue
    
    %rectify detection
    miny = max(1, int32(y - 25));
    maxy = min(size(I_orig, 1), int32(y + 25));
    minx = max(1, int32(x - 25));
    maxx = min(size(I_orig, 2), int32(x + 25));
    patch = markerImages{i}(miny:maxy, minx:maxx, :);
    rescale = 3;
    patch = imresize(patch, rescale);
    I = patch;
    I1 = I(:,:,1) >= minimum2(1) & I(:,:,1) <= maximum2(1);
    I2 = I(:,:,2) >= minimum2(2) & I(:,:,2) <= maximum2(2);
    I3 = I(:,:,3) >= minimum2(3) & I(:,:,3) <= maximum2(3);
    I_T = I1 & I2 & I3;
    I_T = imclose(I_T, strel('disk', 3 * rescale, 0));
    
    A = sum(I_T(:));
    if A == 0
        continue;
    end
    [r, c] = find(I_T);
    x = sum(c) / A / rescale + double(minx) - 1;
    y = sum(r) / A / rescale + double(miny) - 1;
    
    I(:,:,1) = I(:,:,1) + uint8(I_T * 255);
    I(:,:,2:3) = I(:,:,2:3) .* uint8(~repmat(I_T * 255, 1, 1, 2));
    
    errors = [errors, norm([x y] - centers{i})];
    

end
errors
n
mi = sum(errors) / n
sigma = sum((errors - mi).^2) / (n-1)



