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
    %save('markerImages.mat', 'markerImages');
    %return
    centers = {};
    for i = 1:numel(markerImages)
        imshow(markerImages{i})
        set(gcf,'units','normalized','outerposition',[0 0 1 1])
        [x, y] = getpts();
        centers = [centers, [x, y]];
    end
    save('centers.mat', 'centers');
    save('markerImages.mat', 'markerImages');
end

load('markerImages.mat');
load('centers.mat');

% minimum = [240, 240, 0];
% maximum = [255, 255, 200];

minimum = [220, 220, 0];
maximum = [255, 255, 200];

minimum2 = [200, 200, 0];
maximum2 = [255, 255, 230];

errors = [];
errvec = [];
s = 0.5;
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
    [r, c] = find(I_T);
    x = sum(c) / A / s;
    y = sum(r) / A / s;
    
    if norm([x y] - centers{i}) > 2.5
        i
        continue;
    end
    
    err = [x y] - centers{i};
    errvec = [errvec; err];
    errors = [errors, norm(err)];
    
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
mi = sum(errors) / numel(errors)
sigma = sum((errors - mi).^2) / numel(errors)
errors
errvec

figure
set(gca,'FontSize', 18)
for i = 1:size(errvec, 1)
    hold on
    plot([0 errvec(i, 1)], [0 errvec(i, 2)], 'LineWidth', 2)
    plot(errvec(i, 1), errvec(i, 2), 'xb', 'MarkerSize', 20, 'LineWidth', 2)
    hold off
end
hold on
plot(0, 0, 'xr', 'MarkerSize', 20, 'LineWidth', 2)
hold off
return

%bar plotting
%meje = [0, 21, 39, 59, 80];
meje = [0, 25, 50, 75, 100];
for i = 1:4
    subplot(4, 1, i)
    edges = linspace(0, 2, 21);
    bar(histc(errors(meje(i)+1:meje(i+1)), edges));
    title(['Kamera ' num2str(i)], 'FontSize', 18)
    ylim([0 4])
    xlim([0 21])
    set(gca,'FontSize', 18)
    set(gca,'XTick', 0:20);
    set(gca,'XTickLabel', 0:0.1:2);
    %set(gca,'YTick', 0:10:30);
end
%bar plotting
%edges = linspace(0, 1.6, 17);
%bar(histc(errors, edges));
%title(['Kamera ' num2str(i)], 'FontSize', 18)
%ylim([0 5])
%xlim([0 21])
%set(gca,'FontSize', 18)
%set(gca,'XTick', 0:21);
%set(gca,'XTickLabel',edges );
%set(gca,'YTick', 0:5);
%set(gca,'YTickLabel', 0:5)

