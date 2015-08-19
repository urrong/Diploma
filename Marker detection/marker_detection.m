markerImageNames = dir('marker images');
markerImages = {};
for i = 1:numel(markerImageNames)
    if ~markerImageNames(i).isdir
        I = imread(['marker images/' markerImageNames(i).name]);
        markerImages = [markerImages, {I}];
    end
end

% minimum = inf(1, 3);
% maximum = zeros(1, 3);
% 
% for i = 1:numel(markerImages)
%     RGB = impixel(markerImages{i});
%     HSV = rgb2hsv(RGB / 255);
%     maximum = max(maximum, max(HSV));
%     minimum = min(minimum, min(HSV));
% end

minimum
maximum


I = markerImages{9};
I_hsv = rgb2hsv(I);
I1 = I_hsv(:,:,1) >= minimum(1) & I_hsv(:,:,1) <= maximum(1);
I2 = I_hsv(:,:,2) >= minimum(2) & I_hsv(:,:,2) <= maximum(2);
I3 = I_hsv(:,:,3) >= minimum(3) & I_hsv(:,:,3) <= maximum(3);
I_T = I1 & I2 & I3;

I_T = imclose(I_T, strel('disk', 30, 0));
I_T = I_T - imerode(I_T, strel('disk', 3, 0));

AA = zeros(size(I_T, 1), size(I_T, 2), 3);
AA(:,:,1) = I_T * 255;
AA(:,:,2) = I_T * 255;
AA(:,:,3) = I_T * 255;

imshow(I + uint8(AA))

A = sum(I_T(:));
[r, c] = find(I_T);
x = sum(c) / A;
y = sum(r) / A;
hold on
plot(x, y, 'c+', 'MarkerSize', 20, 'LineWidth', 3);
hold off

