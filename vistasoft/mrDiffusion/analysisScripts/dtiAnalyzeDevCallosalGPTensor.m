outPrefix = 'dev';
fgID      = 'occ';
interpNN  = true;

%% load in data
% set path
if ispc
    baseDir = '\\red.stanford.edu\biac2-wandell2\data\DTI_Blind';
    addpath \\white.stanford.edu\home\bob\matlab\stats;
else
    baseDir = '/biac2/wandell2/data/DTI_Blind';
    addpath /home/bob/matlab/stats;
end

fiberDt6 = cell(1);
if interpNN
    load(fullfile(baseDir,sprintf('%s_devInterpNN.mat',fgID)));
    interpMethod = 'nearest';
else
    load(fullfile(baseDir,sprintf('%s_devInterpTL.mat',fgID)));
    interpMethod = 'linear';
end

%% assign basic variables
diffusivityUnitStr = '(\mum^2/ms)';
 
gpID = [ones(1,17) ones(1,50)*2];

numAdult   = sum(gpID==1);
numChild   = sum(gpID==2);
numSub     = numAdult + numChild;
numStep    = size(fiberCC(1).fiberCoord,3);
dt6        = ones(numStep,6,numSub)*NaN;
stepFromCC = -floor(numStep/2):floor(numStep/2);

%% get and arrange dt6 data
for ii = 1:numSub
    cDt6        = permute(fiberDt6{ii},[2 3 1]);
    dt6(:,:,ii) = nanmean(cDt6,3);
end
clear fiberDt6;

%% compute eigenvectors and eigenvalues, compute tensor shape and size

[eigVec,eigVal] = dtiEig(dt6);

normL = eigVal ./ repmat(sum(eigVal,2),[1,3,1]);

% sumD = squeeze(sum(eigVal,2)/1000);

%% align individual's data to average

alignData   = squeeze(normL(:,1,:));
alignDataMu = nanmean(alignData(:,gpID==1),2);

xi         = -40:40;
dt6Aligned = ones(length(xi),6,numSub) * NaN;
alignParam = ones(4,numSub) * NaN;

alignTarget = [stepFromCC',alignDataMu];
alignTarget = alignTarget(~isnan(alignTarget(:,2)),:);

for subID = 1:numSub
    cData = [stepFromCC',alignData(:,subID)];
    cData = cData(~isnan(cData(:,2)),:);
    
    cData(:,2) = dtiSmoothCurve(cData(:,2),0.25);

    alignParam(:,subID) = dtiAlignCurve(cData,alignTarget);

    tmp  = dt6(:,:,subID);
    cDt6 = zeros(size(cData,1),6);
    for ii = 1:size(cData,1)
        cDt6(ii,:) = tmp(stepFromCC==cData(ii,1),:);
    end
    
    cX = dtiWarpStep(cData(:,1),alignParam(1:2,subID));
    
    for ii = 1:6
        dt6Aligned(:,ii,subID) = interp1(cX,cDt6(:,ii),xi,interpMethod);
    end
end

%% compute different measures again ...

[eigVec,eigVal] = dtiEig(dt6Aligned);

% normalized eigenvalues
normL = eigVal ./ repmat(sum(eigVal,2),[1,3,1]);
sumD  = squeeze(sum(eigVal,2)/1000);
radD  = squeeze(mean(eigVal(:,2:3,:),2)/1000);
Cl    = squeeze((eigVal(:,1,:) - eigVal(:,2,:))) ./ squeeze(sum(eigVal,2));
Cp   = 2 * squeeze((eigVal(:,2,:) - eigVal(:,3,:))) ./ squeeze(sum(eigVal,2));

normLMu = zeros(size(normL,1),size(normL,2),2);
normLSd = zeros(size(normLMu));

sumDMu = zeros(size(sumD,1),2);
sumDSd = zeros(size(sumDMu));
radDMu = zeros(size(sumDMu));
radDSd = zeros(size(sumDMu));
ClMu   = zeros(size(sumDMu));
ClSd   = zeros(size(sumDMu));
CpMu   = zeros(size(sumDMu));
CpSd   = zeros(size(sumDMu));

for ii = 1:2
    normLMu(:,:,ii) = nanmean(normL(:,:,gpID==ii),3);
    for jj = 1:3
        normLSd(:,jj,ii) = nanstd(squeeze(normL(:,jj,gpID==ii))')';
    end
    sumDMu(:,ii) = nanmean(sumD(:,gpID==ii),2);
    sumDSd(:,ii) = nanstd(sumD(:,gpID==ii)')';
    radDMu(:,ii) = nanmean(radD(:,gpID==ii),2);
    radDSd(:,ii) = nanstd(radD(:,gpID==ii)')';
    ClMu(:,ii) = nanmean(Cl(:,gpID==ii),2);
    ClSd(:,ii) = nanstd(Cl(:,gpID==ii)')';
    CpMu(:,ii) = nanmean(Cp(:,gpID==ii),2);
    CpSd(:,ii) = nanstd(Cp(:,gpID==ii)')';
end

%% diffusivity figures

figure;
mrUtilResizeFigure(gcf,1500,1000,true);
fontSize = 14;

% mean diffusivity
subplot(2,3,1);
hold on;

% adults
for subID = 1:numAdult
    plot(xi',sumD(:,subID)/3,':','color',[0.7 0.7 0.7]);
end

% average of adults
errorbar(xi',sumDMu(:,1)/3,sumDSd(:,1)/3,'color',[1 0 0],'linewidth',2);

hold off;
set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0.6 1.4],...
    'FontSize',fontSize,'linewidth',2);
box on;
xlabel('Distance from CC (mm)','FontSize',fontSize);
ylabel(sprintf('Mean Diffusivity %s',diffusivityUnitStr),'FontSize',fontSize);
title(sprintf('Adults (N_a_d_u_l_t_s = %d)',numAdult),'FontSize',fontSize);

subplot(2,3,2);
hold on;

% children
for subID = 1:numChild
    plot(xi',sumD(:,subID+numAdult)/3,':','color',[0.7 0.7 0.7]);
end

% average of children
errorbar(xi',sumDMu(:,2)/3,sumDSd(:,2)/3,'color',[0 0 1],'linewidth',2);

hold off;
set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0.6 1.4],...
    'FontSize',fontSize,'linewidth',2);
box on;
xlabel('Distance from CC (mm)','FontSize',fontSize);
ylabel(sprintf('Mean Diffusivity %s',diffusivityUnitStr),'FontSize',fontSize);
title(sprintf('Children (N_c_h_i_l_d_r_e_n = %d)',numChild),'FontSize',fontSize);

subplot(2,3,3);
hold on;

% average of adults
h(1) = plot(xi',sumDMu(:,1)/3,'color',[1 0 0],'linewidth',2);

% average of children
h(2) = plot(xi',sumDMu(:,2)/3,'color',[0 0 1],'linewidth',2);

hold off;
set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0.6 1.4],...
    'FontSize',fontSize,'linewidth',2);
box on;
xlabel('Distance from CC (mm)','FontSize',fontSize);
ylabel(sprintf('Mean Diffusivity %s',diffusivityUnitStr),'FontSize',fontSize);
legend(h,{'Adults','Children'},'location','North','FontSize',fontSize);

% radial diffusivity
subplot(2,3,4);
hold on;

% adults
for subID = 1:numAdult
    plot(xi',radD(:,subID),':','color',[0.7 0.7 0.7]);
end

% average of adults
errorbar(xi',radDMu(:,1),radDSd(:,1),'color',[1 0 0],'linewidth',2);

hold off;
set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0.3 1.1],...
    'FontSize',fontSize,'linewidth',2);
box on;
xlabel('Distance from CC (mm)','FontSize',fontSize);
ylabel(sprintf('Radial Diffusivity %s',diffusivityUnitStr),'FontSize',fontSize);
title(sprintf('Adults (N_a_d_u_l_t_s = %d)',numAdult),'FontSize',fontSize);

subplot(2,3,5);
hold on;

% children
for subID = 1:numChild
    plot(xi',radD(:,subID+numAdult),':','color',[0.7 0.7 0.7]);
end

% average of children
errorbar(xi',radDMu(:,2),radDSd(:,2),'color',[0 0 1],'linewidth',2);

hold off;
set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0.3 1.1],...
    'FontSize',fontSize,'linewidth',2);
box on;
xlabel('Distance from CC (mm)','FontSize',fontSize);
ylabel(sprintf('Radial Diffusivity %s',diffusivityUnitStr),'FontSize',fontSize);
title(sprintf('Children (N_c_h_i_l_d_r_e_n = %d)',numChild),'FontSize',fontSize);

subplot(2,3,6);
hold on;

% average of adults
h(1) = plot(xi',radDMu(:,1),'color',[1 0 0],'linewidth',2);

% average of children
h(2) = plot(xi',radDMu(:,2),'color',[0 0 1],'linewidth',2);

hold off;
set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0.3 1.1],...
    'FontSize',fontSize,'linewidth',2);
box on;
xlabel('Distance from CC (mm)','FontSize',fontSize);
ylabel(sprintf('Radial Diffusivity %s',diffusivityUnitStr),'FontSize',fontSize);
legend(h,{'Adults','Children'},'location','North','FontSize',fontSize);

mrUtilPrintFigure(fullfile(baseDir,sprintf('%s_%s_diffusivity.eps',outPrefix,fgID)));

% legend(h,[{'NV Avg'},lvSub],'location','North','FontSize',fontSize);

%% shape index figures

figure;
mrUtilResizeFigure(gcf,1500,1000,true);
fontSize = 14;

% linearity
subplot(2,3,1);
hold on;

% adults
for subID = 1:numAdult
    plot(xi',Cl(:,subID),':','color',[0.7 0.7 0.7]);
end

% average of adults
errorbar(xi',ClMu(:,1),ClSd(:,1),'color',[1 0 0],'linewidth',2);

hold off;
set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0 0.6],...
    'FontSize',fontSize,'linewidth',2);
box on;
xlabel('Distance from CC (mm)','FontSize',fontSize);
ylabel('Linearity','FontSize',fontSize);
title(sprintf('Adults (N_a_d_u_l_t_s = %d)',numAdult),'FontSize',fontSize);

subplot(2,3,2);
hold on;

% children
for subID = 1:numChild
    plot(xi',Cl(:,subID+numAdult),':','color',[0.7 0.7 0.7]);
end

% average of children
errorbar(xi',ClMu(:,2),ClSd(:,2),'color',[0 0 1],'linewidth',2);

hold off;
set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0 0.6],...
    'FontSize',fontSize,'linewidth',2);
box on;
xlabel('Distance from CC (mm)','FontSize',fontSize);
ylabel('Linearity','FontSize',fontSize);
title(sprintf('Children (N_c_h_i_l_d_r_e_n = %d)',numChild),'FontSize',fontSize);

subplot(2,3,3);
hold on;

% average of adults
h(1) = plot(xi',ClMu(:,1),'color',[1 0 0],'linewidth',2);

% average of children
h(2) = plot(xi',ClMu(:,2),'color',[0 0 1],'linewidth',2);

hold off;
set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0 0.6],...
    'FontSize',fontSize,'linewidth',2);
box on;
xlabel('Distance from CC (mm)','FontSize',fontSize);
ylabel('Linearity','FontSize',fontSize);
legend(h,{'Adults','Children'},'location','North','FontSize',fontSize);

% planarity
subplot(2,3,4);
hold on;

% adults
for subID = 1:numAdult
    plot(xi',Cp(:,subID),':','color',[0.7 0.7 0.7]);
end

% average of adults
errorbar(xi',CpMu(:,1),CpSd(:,1),'color',[1 0 0],'linewidth',2);

hold off;
set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0 0.6],...
    'FontSize',fontSize,'linewidth',2);
box on;
xlabel('Distance from CC (mm)','FontSize',fontSize);
ylabel('Planarity','FontSize',fontSize);
title(sprintf('Adults (N_a_d_u_l_t_s = %d)',numAdult),'FontSize',fontSize);

subplot(2,3,5);
hold on;

% children
for subID = 1:numChild
    plot(xi',Cp(:,subID+numAdult),':','color',[0.7 0.7 0.7]);
end

% average of children
errorbar(xi',CpMu(:,2),CpSd(:,2),'color',[0 0 1],'linewidth',2);

hold off;
set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0 0.6],...
    'FontSize',fontSize,'linewidth',2);
box on;
xlabel('Distance from CC (mm)','FontSize',fontSize);
ylabel('Planarity','FontSize',fontSize);
title(sprintf('Children (N_c_h_i_l_d_r_e_n = %d)',numChild),'FontSize',fontSize);

subplot(2,3,6);
hold on;

% average of adults
h(1) = plot(xi',CpMu(:,1),'color',[1 0 0],'linewidth',2);

% average of children
h(2) = plot(xi',CpMu(:,2),'color',[0 0 1],'linewidth',2);

hold off;
set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0 0.6],...
    'FontSize',fontSize,'linewidth',2);
box on;
xlabel('Distance from CC (mm)','FontSize',fontSize);
ylabel('Planarity','FontSize',fontSize);
legend(h,{'Adults','Children'},'location','North','FontSize',fontSize);

mrUtilPrintFigure(fullfile(baseDir,sprintf('%s_%s_shape.eps',outPrefix,fgID)));

%% log tensor tests on original tensors

% set FDR parameters
fdrVal  = 0.10;
fdrType = 'original';

% log-transform
logEigVal = log(eigVal);
logDt6    = dtiEigComp(eigVec,logEigVal);

% computer tensor group summary
origDt6 = repmat(struct('mean',[],'stdev',[],'n',[]),2,1);
for ii = 1:2
    [origDt6(ii).mean, origDt6(ii).stdev, origDt6(ii).n] = dtiLogTensorMean(logDt6(:,:,gpID==ii));
end

% Test for eigenvalue differences
[origLTest.T, origLTest.distr, origLTest.df] = ...
    dtiLogTensorTest('val', ...
    origDt6(1).mean, origDt6(1).stdev, origDt6(1).n, ...
    origDt6(2).mean, origDt6(2).stdev, origDt6(2).n);

origLTest.T(isnan(origLTest.T)) = 0;

% convert eigenvalue F-statistics to p-values
origLTest.p = 1-fcdf(origLTest.T,origLTest.df(1),origLTest.df(2));

% calculate FDR
[origLTest.nSignif,origLTest.indSignif] = fdr(origLTest.p,fdrVal,fdrType);

if origLTest.nSignif
    origLTest.fdrCorrectedPThres = max(origLTest.p(origLTest.indSignif));
end

% p-value plot

figure;
hold on;
fontSize = 14;

if origLTest.nSignif
    pLevel = origLTest.fdrCorrectedPThres;
    plot([xi(1)-1 xi(end)+1],-log10([pLevel pLevel]),'k--','linewidth',2);
end
plot(xi',-log10(origLTest.p),'color','g','linewidth',2);
if origLTest.nSignif
    plot(xi(origLTest.indSignif),-log10(origLTest.p(origLTest.indSignif)),...
        '*','markersize',12,'color','g','linewidth',2);
end
hold off;
set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0 8],...
    'FontSize',fontSize,'linewidth',2);
box on;
grid on;
xlabel('Distance from CC (mm)','FontSize',fontSize);
ylabel('Original Tensor Eigenvalue Test (-log10(p))','FontSize',fontSize);
title('Adults vs. Children','FontSize',fontSize);

mrUtilPrintFigure(fullfile(baseDir,sprintf('%s_%s_origLTest.eps',outPrefix,fgID)));

%% log tensor tests on normalized tensors

% set FDR parameters
fdrVal  = 0.10;
fdrType = 'original';

% log-transform
logNormL   = log(normL);
logNormDt6 = dtiEigComp(eigVec,logNormL);

normDt6 = repmat(struct('mean',[],'stdev',[],'n',[]),2,1);
for ii = 1:2
    [normDt6(ii).mean, normDt6(ii).stdev, normDt6(ii).n] = dtiLogTensorMean(logNormDt6(:,:,gpID==ii));
end

% Test for eigenvalue differences
[normLTest.T, normLTest.distr, normLTest.df] = ...
    dtiLogTensorTest('val', ...
    normDt6(1).mean, normDt6(1).stdev, normDt6(1).n, ...
    normDt6(2).mean, normDt6(2).stdev, normDt6(2).n);

normLTest.T(isnan(normLTest.T)) = 0;

% convert eigenvalue F-statistics to p-values
normLTest.p = 1-fcdf(normLTest.T,normLTest.df(1),normLTest.df(2));

% calculate FDR
[normLTest.nSignif,normLTest.indSignif] = fdr(normLTest.p,fdrVal,fdrType);

if normLTest.nSignif
    normLTest.fdrCorrectedPThres = max(normLTest.p(normLTest.indSignif));
end

% p-value plot

figure;
hold on;
fontSize = 14;

if normLTest.nSignif
    pLevel = normLTest.fdrCorrectedPThres;
    plot([xi(1)-1 xi(end)+1],-log10([pLevel pLevel]),'k--','linewidth',2);
end
plot(xi',-log10(normLTest.p),'color','g','linewidth',2);
if normLTest.nSignif
    plot(xi(normLTest.indSignif),-log10(normLTest.p(normLTest.indSignif)),...
        '*','markersize',12,'color','g','linewidth',2);
end
hold off;
set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0 8],...
    'FontSize',fontSize,'linewidth',2);
box on;
grid on;
xlabel('Distance from CC (mm)','FontSize',fontSize);
ylabel('Normalized Tensor Eigenvalue Test (-log10(p))','FontSize',fontSize);
title('Adults vs. Children','FontSize',fontSize);

mrUtilPrintFigure(fullfile(baseDir,sprintf('%s_%s_normLTest.eps',outPrefix,fgID)));

%%
% 3D ellipsoid plot

% newNumStep = length(xi);
% coords     = ones(newNumStep,3,numSub);
% 
% for subID = 1:numSub
%     cInd = zeros(newNumStep,1);
%     for ii = 1:newNumStep
%         cInd(ii) = find(stepFromCC == xi(ii));
%     end
%     coords(:,:,subID) = squeeze(nanmean(fiberCC(subID).fiberCoord(:,:,cInd),2))';
% end
% 
% origDt6DataMu = zeros(size(dt6Aligned,1),size(dt6Aligned,2),2);
% coordsMu      = zeros(size(coords,1),size(coords,2),2);
% for ii = 1:2
%     [eigVec,eigVal] = dtiEig(origDt6(ii).mean);
%     origDt6DataMu(:,:,ii) = dtiEigComp(eigVec,exp(eigVal));
%     coordsMu(:,:,ii)      = mean(coords(:,:,gpID==ii),3);
% end
% 
% figure;
% hold on;
% 
% for ii = 1:newNumStep
%     dtiDrawTensor(origDt6DataMu(ii,:,1),coordsMu(ii,:,1)*100','s',...
%         [1 0 0],[0.05 0.05 0.05]);
%     dtiDrawTensor(origDt6DataMu(ii,:,2),coordsMu(ii,:,2)*100','s',...
%         [0 0 1],[0.05 0.05 0.05]);
% end
% title([]);


%% OLD
% shape index figures

% A = [1/3 1/3 1; 1/2 1/2 1; 1 0 1];
% B = [0 0; 0 1; 1 0];
% T = A\B;
% 
% figure;
% mrUtilResizeFigure(gcf,500,1000,true);
% fontSize = 14;
% 
% subplot(2,1,1);
% hold on;
% subplot(2,1,2);
% hold on;
% 
% % nv's
% for subID = 1:numNV
%     shapeIndex = [ occNormL(:,1,subID+1) ...
%                    occNormL(:,2,subID+1) ...
%                    ones(size(occNormL(:,1,subID+1))) ] * T;
%     subplot(2,1,1);
%     plot(xi',shapeIndex(:,1),'color',[0.7 0.7 0.7]);
%     subplot(2,1,2);
%     plot(xi',shapeIndex(:,2),'color',[0.7 0.7 0.7]);
% end
% 
% % average of nv's
% shapeIndex = [ nvOccNormLMu(:,1) ...
%                nvOccNormLMu(:,2) ...
%                ones(size(nvOccNormLMu(:,1))) ] * T;
% 
% h = zeros(6,1);
% subplot(2,1,1);
% plot(xi',shapeIndex(:,1),'color','b','linewidth',2);
% subplot(2,1,2);
% h(1) = plot(xi',shapeIndex(:,2),'color','b','linewidth',2);
% 
% % MM and other LV patients
% for ii = 1:5
%     shapeIndex = [ occNormL(:,1,lvOrd(ii)) ...
%                    occNormL(:,2,lvOrd(ii)) ...
%                    ones(size(occNormL(:,1,lvOrd(ii)))) ] * T;
%     subplot(2,1,1);
%     plot(xi',shapeIndex(:,1),'color',lvCol(ii,:));
%     subplot(2,1,2);
%     h(ii+1) = plot(xi',shapeIndex(:,2),'color',lvCol(ii,:));
% end
% 
% subplot(2,1,1);
% hold off;
% set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0 0.6],...
%     'FontSize',fontSize,'linewidth',2);
% box on;
% xlabel('Distance from CC (mm)','FontSize',fontSize);
% ylabel('Linearity','FontSize',fontSize);
% 
% subplot(2,1,2);
% hold off;
% set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0 0.6],...
%     'FontSize',fontSize,'linewidth',2);
% box on;
% xlabel('Distance from CC (mm)','FontSize',fontSize);
% ylabel('Planarity','FontSize',fontSize);
% 
% legend(h,...
%     [{'NV Avg'},lvSub],'location','North','FontSize',fontSize);
% 
% %% 
% figure;
% mrUtilResizeFigure(gcf,1500,500,true);
% fontSize = 12;
% 
% subplot(1,2,1);
% hold on;
% 
% plot3([xi(1)-1 xi(end)+1],[0 0],[0 0],'k-','linewidth',2);
% plot3([xi(1)-1 xi(end)+1],[0 0],[1 1],'k-','linewidth',2);
% plot3([xi(1)-1 xi(end)+1],[1 1],[0 0],'k-','linewidth',2);
% plot3([xi(1)-1 xi(1)-1],[0 1],[1 0],'k-','linewidth',2);
% plot3([xi(end)+1 xi(end)+1],[0 1],[1 0],'k-','linewidth',2);
% 
% for subID = 1:numNV
%     shapeSpace = [occNormL(:,1,subID+1) occNormL(:,2,subID+1) ones(size(occNormL(:,1,subID+1)))] * T;
%     plot3(xi',shapeSpace(:,1),shapeSpace(:,2),...
%         'color',[0.7 0.7 0.7]);
% end
% 
% shapeSpace = [nvOccNormLMu(:,1) nvOccNormLMu(:,2) ones(size(nvOccNormLMu(:,1)))] * T;
% 
% h1 = plot3(xi',shapeSpace(:,1),shapeSpace(:,2),...
%     'color','b','linewidth',2);
% 
% subID = 20; % MM
% shapeSpace = [occNormL(:,1,subID) occNormL(:,2,subID) ones(size(occNormL(:,1,subID)))] * T;
% h2 = plot3(xi',shapeSpace(:,1),shapeSpace(:,2),...
%     'color','r','linewidth',2);
% 
% hold off;
% set(gca, ...
%     'xlim',[xi(1)-1 xi(end)+1], ...
%     'ylim',[0 1], ...
%     'zlim',[0 1],...
%     'ytick',0:0.2:1,'ztick',0:0.2:1,...
%     'FontSize',fontSize,'linewidth',2);
% box on;
% xlabel('Distance from CC (mm)','FontSize',fontSize);
% ylabel('Linearity','FontSize',fontSize);
% zlabel('Planarity','FontSize',fontSize);
% legend([h1 h2],...
%     {'NV Average','MM'},'FontSize',fontSize);
% 
% view(20,-30);
% 
% % size plot
% subplot(1,2,2);
% hold on;
% for subID = 1:numNV
%     plot(xi',occSumD(:,subID+1),...
%         'color',[0.7 0.7 0.7]);
% end
% h1 = errorbar(xi',nvOccSumDMu(:),nvOccSumDSd(:),...
%     'color','b','linewidth',2);
% 
% subID = 20; % MM
% h2 = plot(xi',occSumD(:,subID),...
%     'color','r','linewidth',2);
% 
% hold off;
% set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[2.3 4.3],...
%     'FontSize',fontSize,'linewidth',2);
% box on;
% xlabel('Distance from CC (mm)','FontSize',fontSize);
% ylabel(sprintf('Total Diffusivity %s',diffusivityUnitStr),'FontSize',fontSize);
% legend([h1 h2],...
%     {'NV Average','MM'},'Location','North','FontSize',fontSize);
% 
% % 3D ellipsoid plot
% 
% newNumStep = length(xi);
% occCoords  = ones(newNumStep,3,numSub);
% for subID = 1:numSub
%     cInd = zeros(newNumStep,1);
%     for ii = 1:newNumStep
%         cInd(ii) = find(stepFromCC == xi(ii));
%     end
%     occCoords(:,:,subID) = squeeze(nanmean(fiberCC(subID).fiberCoord(:,:,cInd),2))';
% end
% 
% occNormDt6     = dtiEigComp(occEigVec,occNormL);
% nvOccNormDt6Mu = dtiLogTensorMean(occNormDt6(:,:,gpID==1));
% nvOccCoordsMu  = mean(occCoords(:,:,gpID==1),3);
% 
% figure;
% hold on;
% 
% for ii = 1:newNumStep
%     dtiDrawTensor(nvOccNormDt6Mu(ii,:,1),nvOccCoordsMu(ii,:)','s',...
%         [0 0 1],[0.05 0.05 0.05]);
%     dtiDrawTensor(occNormDt6(ii,:,20),occCoords(ii,:,20)','s',...
%         [1 0 0],[0.05 0.05 0.05]);
% end
% title([]);
% 
% %%
% % log-transform
% occLogEigVal = log(occEigVal);
% occLogDt6    = dtiEigComp(occEigVec, occLogEigVal);
% 
% % computer tensor group summary
% [nvOccLogTensor.mean, nvOccLogTensor.stdev, nvOccLogTensor.n] = ...
%     dtiLogTensorMean(occLogDt6(:,:,gpID==1));
% 
% % Test for eigenvalue differences
% [occVal.T, occVal.distr, occVal.df] = ...
%     dtiLogTensorTest('val', nvOccLogTensor.mean, nvOccLogTensor.stdev, ...
%     nvOccLogTensor.n, occLogDt6(:,:,23));
% 
% % convert eigenvalue F-statistics to p-values
% occVal.p = 1-fcdf(occVal.T,occVal.df(1),occVal.df(2));
% 
% figure;
% hold on;
% plot([xi(1)-1 xi(end)+1],[0.05 0.05],'k--');
% plot(xi',occVal.p,'r','linewidth',2);
% hold off;
% 
% set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0 1],...
%     'FontSize',fontSize,'linewidth',2);
% box on;
% xlabel('Distance from CC (mm)','FontSize',fontSize);
% ylabel('p-values','FontSize',fontSize);
% 
% %%
% % log-transform
% occLogNormL   = log(occNormL);
% occLogNormDt6 = dtiEigComp(occEigVec, occLogNormL);
% 
% % computer tensor group summary
% [nvOccLogNormTensor.mean, nvOccLogNormTensor.stdev, nvOccLogNormTensor.n] = ...
%     dtiLogTensorMean(occLogNormDt6(:,:,gpID==1));
% 
% % Test for eigenvalue differences
% [occNormL.T, occNormL.distr, occNormL.df] = ...
%     dtiLogTensorTest('val', nvOccLogNormTensor.mean, nvOccLogNormTensor.stdev, ...
%     nvOccLogNormTensor.n, occLogNormDt6(:,:,23));
% 
% % convert eigenvalue F-statistics to p-values
% occNormL.p = 1-fcdf(occNormL.T,occNormL.df(1),occNormL.df(2));
% 
% figure;
% hold on;
% plot([xi(1)-1 xi(end)+1],[0.05 0.05],'k--');
% plot(xi',occNormL.p,'r','linewidth',2);
% hold off;
% 
% set(gca,'xlim',[xi(1)-1 xi(end)+1],'ylim',[0 1],...
%     'FontSize',fontSize,'linewidth',2);
% box on;
% xlabel('Distance from CC (mm)','FontSize',fontSize);
% ylabel('p-values','FontSize',fontSize);
