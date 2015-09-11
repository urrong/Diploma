load('allErrors.mat')

s = 0;
n = 0;
d = [];
for i = 1:size(allErrors, 1)
    d = [d norm(allErrors(i, :))];
    if norm(allErrors(i, :)) < 5
        s = s + norm(allErrors(i, :));
        n = n + 1;
    end
%     hold on
%     plot3([0, allErrors(i, 1)], [0, allErrors(i, 2)], [0, allErrors(i, 3)])
%     hold off 
end
allErrors = [allErrors d'];
nbins = 20;
bins = linspace(0, 5, nbins+1);
allErrors(allErrors > 5) = 5;
h = histc(allErrors(:, 4), bins);
bar(h)
h

