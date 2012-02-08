% rd_zCombo.m

%% z-contrast combo
thresh = 2;
midx = zContrasts(:,1)<thresh & zContrasts(:,4)<-thresh;
pidx = zContrasts(:,2)>thresh & zContrasts(:,4)>thresh;
nnz(midx&pidx)
zCombo = pidx-midx;
nnz(zCombo)

%% store in zContrasts
zContrasts(:,7) = zCombo;

%% image
figure
imagesc([midx pidx])
