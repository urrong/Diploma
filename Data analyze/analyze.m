load('points_z_4')

% worldPoints = [0 0 2;
%                0 60 2;
%                120 0 2;
%                120 60 2;
%                240 0 2;
%                240 60 2];
           
worldPoints = [0 0 62.6;
               0 60 62.6;
               120 0 62.6;
               120 60 62.6;
               240 0 62.6;
               240 60 62.6];

detectedPoints = {a b c d e f};
err = [];
colors = 'rgbcym';
for i = 1:size(worldPoints, 1)
    w = worldPoints(i, :);
    detected = detectedPoints{i};
    for j = 1:size(detected, 1)
        d = detected(j, :);
        b = d - w;
        %allErrors = [allErrors; b];
        err = [err, norm(b)];
%         hold on
%         plot3([0, b(1)], [0, b(2)], [0, b(3)], ['-' colors(i)], 'LineWidth', 2)
%         hold off 
    end
end
% xlabel('x (cm)', 'FontSize', 18)
% ylabel('y (cm)', 'FontSize', 18)
% zlabel('z (cm)', 'FontSize', 18)
% set(gca,'FontSize', 18)
mi = sum(err) / numel(err)
sigma2 = sum((err - mi).^2) / numel(err)