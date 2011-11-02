function   VisualizeSuperFibersGroup(SuperFibersGroup, clusterlabels)

%For clusters containing more than one fiber.
%Various ways to visualize every cluster
%ER 02/2008 SCSNL


nfibers=size(SuperFibersGroup.n, 2); 
numNodes=size(SuperFibersGroup.fibers{1}, 2); %These are means

for i=1:nfibers
   curves(:, :, i)=SuperFibersGroup.fibers{i};
   varmx(:, :, i)=SuperFibersGroup.fibervarcovs{i};

end

  figure; 
for clust=1:size(SuperFibersGroup.n, 2)
    
%figure;  subplot(2, 1, 1); 
%tubeplot(curves(1, :, clust), curves(2, :, clust), curves(3, :, clust), genvar(:, :, clust)); 
%tubeplot(curves(1, :, clust), curves(2, :, clust), curves(3, :, clust), RADIUS, COLOR); 
%Display a tubeplot with central line along the SuperFiber node means, and
%with radius supplied by generalized variance???
  
    for nodeI=1:numNodes
    [determinant, varcovmatrix] =detLowTriMxVectorized(varmx(:, nodeI, clust));
    genvar(nodeI, clust)=sqrt(trace(diag(eig(varcovmatrix)))./3);
    end
if size(clusterlabels==clust)<2
continue
end

    tubeplot(curves(1, :, clust), curves(2, :, clust), curves(3, :, clust), genvar(:, clust));  %CHECK THIS!!!!! THAT SQRT of TRACE of EIGENVALUES is 2bused. MAYBE NOT TRACE BUT AVERAGE?
    %This plots genvar at 1SD, can do 2...to cover 73%or so...

%THIS SNIPPET DRAWS UGLY ELLIPSOIDS
%    for nodeI=1:numNodes
%    [determinant, varcovmatrix] =detLowTriMxVectorized(varmx(:, nodeI, clust))
%    plot_gaussian_ellipsoid(curves(:, nodeI, clust), varcovmatrix, 2);    hold on; 
%    end

%THIS SNIPPET will make individual fiber tubes for this cluster. 
%subplot(2, 1, 2); vis_fib_cluster(clust, clusterlabels,  fibergroup1); title(['Cluster' num2str(clust) ' nfibers ' num2str(size(find(clusterlabels==clust), 1))]);

%TODO: TUBEPLOT WITH ELLIPSOID CROSS-SECTION that reflects VARCOV MATRIX
hold on; 
end


