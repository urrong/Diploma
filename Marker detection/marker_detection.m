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
        [x, y] = getpts();
        centers = [centers, [x, y]];
    end
    save('centers.mat', 'centers');
    
    
    minimum = inf(1, 3);
    maximum = zeros(1, 3);
    
    for i = 1:numel(markerImages)
        RGB = impixel(markerImages{i});
        %HSV = rgb2hsv(RGB / 255);
        HSV = RGB;
        maximum = max(maximum, max(HSV));
        minimum = min(minimum, min(HSV));
    end
    
    minimum
    maximum
end
load('centers.mat')
minimum = [200, 200, 0];
maximum = [255, 255, 180];

errors = zeros(1, numel(centers));
s = 1;
for i = 15%1:numel(markerImages)
    I = imresize(markerImages{i}, s);
    
    I1 = I(:,:,1) >= minimum(1) & I(:,:,1) <= maximum(1);
    I2 = I(:,:,2) >= minimum(2) & I(:,:,2) <= maximum(2);
    I3 = I(:,:,3) >= minimum(3) & I(:,:,3) <= maximum(3);
    I_T = I1 & I2 & I3;
    
    
    %I_T = imdilate(I_T, strel('disk', 3, 0));
    
%     I(:,:,1) = I(:,:,1) + uint8(I_T * 255);
%     I(:,:,2:3) = I(:,:,2:3) .* uint8(~repmat(I_T * 255, 1, 1, 2)); 
    
    A = sum(I_T(:));
    [r, c] = find(I_T);
    x = sum(c) / A / s
    y = sum(r) / A / s
    
    errors(i) = norm([x y] - centers{i});
    
    imshow(I)
    hold on
    plot(x, y, 'g+', 'MarkerSize', 50, 'LineWidth', 3);
    hold off
    pause(0.5)
end
errors
mi = sum(errors) / numel(errors)
sigma = sum((errors - mi).^2) / (numel(errors)-1)



