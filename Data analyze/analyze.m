load('points_4')

worldPoints = [0 40 76;
               0 80 76;
               40 40 76;
               40 80 76;
               80 40 76;
               80 80 76;
               120, 40, 76;
               120, 80, 76];

colors = [1 0 0;
          0 1 0;
          0 0 1;
          1 1 0;
          1 0 1;
          0 1 1;
          0 0 0;
          1 0.5 0];

detectedPoints = {a b c d e f g h};

m = 1000000;
for i = 1:numel(detectedPoints)
    m = min(m, size(detectedPoints{i}, 1));
end
for i = 1:numel(detectedPoints)
    detectedPoints{i} = detectedPoints{i}(1:m, :);
end
m * 8
errors = [];
vecErrors = [];

for i = 1:size(worldPoints, 1)
    w = worldPoints(i, :);
    detected = detectedPoints{i};
    for j = 1:size(detected, 1)
        error = detected(j, :) - w;
        vecErrors = [vecErrors; error];
        errors = [errors, norm(error)];
        hold on
        plot3([0, error(1)], [0, error(2)], [0, error(3)], 'Color', colors(i, :), 'LineWidth', 1)
        hold off 
    end
end
xlabel('x (cm)', 'FontSize', 18)
ylabel('y (cm)', 'FontSize', 18)
zlabel('z (cm)', 'FontSize', 18)
set(gca,'FontSize', 18)

vecErrors = [vecErrors errors'];
mi = sum(errors) / numel(errors);
sigma2 = sum((errors - mi).^2) / numel(errors);
[mi sigma2]

nbins = 16;
bins = linspace(-6, 10, nbins + 1);
labels = ['napaka na osi x (cm)';
          'napaka na osi y (cm)';
          'napaka na osi z (cm)';
          'skupna napaka (cm)  ';];

figure
for i = 1:4
    subplot(4, 1, i)
    bar(histc(vecErrors(:, i), bins))
    %sum(histc(vecErrors(:, i), bins))
    xlabel(labels(i, :), 'FontSize', 18)
    xlim([0 nbins+1])
    ylim([0 150])
    set(gca,'FontSize', 18)
    set(gca,'XTick', 0:nbins+1);
    set(gca,'XTickLabel', [bins 11]);
end



