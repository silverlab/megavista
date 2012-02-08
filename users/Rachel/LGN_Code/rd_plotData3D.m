% rd_plotData3D

a = any(brainMapToPlot,3);

i = find(a);
[xx yy dummy zz] = ind2sub(size(a),i);

for idx = 1:length(xx)
    cc(idx,:) = brainMapToPlot(xx(idx), yy(idx), :, zz(idx));
end

figure
scatter3(xx,yy,zz,1000,cc,'.')
axis equal

xlabel('left <--> right')
ylabel('posterior <--> anterior')
zlabel('ventral <--> dorsal')