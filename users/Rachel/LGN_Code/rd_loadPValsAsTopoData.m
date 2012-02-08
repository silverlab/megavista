% rd_loadPValsAsTopoData.m

load ../../Inplane/GLMs/MVP.mat
pvalmap = map{2};
ind = sub2ind(size(pvalmap),figData.coordsInplane(1,:), ...
    figData.coordsInplane(2,:), figData.coordsInplane(3,:));
pvals = pvalmap(ind);
topoData = pvals';