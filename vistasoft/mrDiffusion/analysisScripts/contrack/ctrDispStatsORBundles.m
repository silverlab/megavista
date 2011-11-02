function dispStatsORBundles(wDir, statsFile, clThresh, bDoAuxPlots)

evStats = load(fullfile(wDir,statsFile));
subjDirs = evStats.subjDirs;
pathFiles = evStats.pathFiles;
numVars = size(pathFiles,2)+1;
eigMean = zeros([length(subjDirs),2,numVars,3]);
bStatsContainAll = size(evStats.stats,3)==numVars;
if(ieNotDefined('bDoAuxPlots'))
    bDoAuxPlots = 0;
end

for ss = 1:length(subjDirs)
    disp(['Computing diffusivity values for ' subjDirs{ss} ' ...']);
    for hh=1:2
        % Look at mean l1,l2,l3 for each OR bundle in every subj/hem
        for pp=1:numVars
            if pp==numVars && ~bStatsContainAll
                curDir = fullfile(wDir,subjDirs{ss});
                dt = dtiLoadDt6(fullfile(curDir,'dti06','dt6.mat'));
                xMid = - round(dt.xformToAcpc(1,4)/dt.xformToAcpc(1,1));
                if(hh==1)
                    [eigVec, eigVal] = dtiEig(dt.dt6(1:xMid-1,:,:,:));
                else
                    [eigVec, eigVal] = dtiEig(dt.dt6(xMid:end,:,:,:));
                end
                evStats.stats{ss,hh,pp} = reshape(eigVal,size(eigVal,1)*size(eigVal,2)*size(eigVal,3),size(eigVal,4));
            else
                eigVal = evStats.stats{ss,hh,pp};
            end
            [cl, cp, cs] = dtiComputeWestinShapes(eigVal);
            [fa, md, rd] = dtiComputeFA(eigVal);
            for ll=1:3
                if(ndims(eigVal)>2)
                    temp = eigVal(:,:,:,ll);
                    eigMean(ss,hh,pp,ll) = mean(temp(cl>clThresh));
                else
                    eigMean(ss,hh,pp,ll) = mean(eigVal(cl>clThresh,ll));
                end
            end
            rdMean(ss,hh,pp) = mean(rd(cl>clThresh));
        end
    end
end
if ~bStatsContainAll
    save(fullfile(wDir,statsFile),'-struct','evStats');
end

testVec = reshape(eigMean,[size(eigMean,1)*size(eigMean,2) size(eigMean,3) size(eigMean,4)]);
testVecMD = mean(testVec,3);
% Mean diffusivity two-sample ttest
[hMD_MeyerCentral, pMD_MeyerCentral] = ttest2(testVecMD(:,1),testVecMD(:,2));
[hMD_MeyerDirect, pMD_MeyerDirect] = ttest2(testVecMD(:,1),testVecMD(:,3));
[hMD_MeyerAll, pMD_MeyerAll] = ttest2(testVecMD(:,1),testVecMD(:,4));
[hMD_ORAll, pMD_ORAll] = ttest2(mean(testVecMD(:,1:3),2),testVecMD(:,4));

% Longitudinal diffusivity two-sample ttest
[hL_MC, pL_MC] = ttest2(testVec(:,1,1),testVec(:,2,1));
[hL_MD, pL_MD] = ttest2(testVec(:,1,1),testVec(:,3,1));
[hL_MA, pL_MA] = ttest2(testVec(:,1,1),testVec(:,4,1));

% Radial diffusivity two-sample ttest
testVecR = reshape(rdMean,[size(rdMean,1)*size(rdMean,2) size(rdMean,3)]);
[hR_MC, pR_MC] = ttest2(testVecR(:,1),testVecR(:,2));
[hR_MD, pR_MD] = ttest2(testVecR(:,1),testVecR(:,3));
[hR_MA, pR_MA] = ttest2(testVecR(:,1),testVecR(:,4));

testVecCL = squeeze(testVec(:,:,1) - testVec(:,:,2)) ./ squeeze(sum(testVec(:,:,:),3));
% Linearity two-sample ttest
[hCL_MeyerCentral, pCL_MeyerCentral] = ttest2(testVecCL(:,1),testVecCL(:,2));
[hCL_MeyerDirect, pCL_MeyerDirect] = ttest2(testVecCL(:,1),testVecCL(:,3));
[hCL_MeyerAll, pCL_MeyerAll] = ttest2(testVecCL(:,1),testVecCL(:,4));
[hCL_ORAll, pCL_ORAll] = ttest2(mean(testVecCL(:,1:3),2),testVecCL(:,4));


% Create scatter plot for longitudinal vs. radial diffusivity averages
figure;
hold on;
bAvgORBundles=1;
if bAvgORBundles
    markerVec = {'k','sk'};
    scatter(mean(testVec(:,1:3,1),2),mean(testVecR(:,1:3,1),2),50,markerVec{1});
    scatter(testVec(:,4,1),testVecR(:,4,1),50,markerVec{2},'MarkerFaceColor','k');
    legend('OR','all white matter');
else
    markerVec = {'b','r','g','*m'};
    for mm=1:4
        scatter(testVec(:,mm,1),testVecR(:,mm,1),50,markerVec{mm});
    end
    legend('Meyer','Central','Direct','All WM');
end
xLabel('Longitudinal diffusivity ( \mum^2/ms)');
yLabel('Radial diffusivity ( \mum^2/ms)');

% Draw lines of constant mean diffusivity and linearity
meanLD = mean(reshape(testVec(:,1:3,1),16*3,1));
meanRD = mean(reshape(testVecR(:,1:3,1),16*3,1));
constMD = (2*meanRD + meanLD)/3;
%slopeMD = (3*constMD - meanLD)/2;
aL = meanLD-0.4;
aR = (3*constMD - aL)/2;
bL = meanLD+0.4;
bR = (3*constMD - bL)/2;
plot([aL bL], [aR bR], '-k')

meanLD = mean(reshape(testVec(:,4,1),16,1));
meanRD = mean(reshape(testVecR(:,4,1),16,1));
constMD = (2*meanRD + meanLD)/3;
%slopeMD = (3*constMD - meanLD)/2;
aL = meanLD-0.4;
aR = (3*constMD - aL)/2;
bL = meanLD+0.4;
bR = (3*constMD - bL)/2;
plot([aL bL], [aR bR], '-k')

meanLD = mean(reshape(testVec(:,:,1),16*4,1));
mean2D = mean(reshape(testVec(:,:,2),16*4,1));
mean3D = mean(reshape(testVec(:,:,3),16*4,1));
meanRD = mean(reshape(testVecR(:,:,1),16*4,1));
%constCL = (meanLD-meanRD)/(meanLD+2*meanRD);
constCL = (meanLD-mean2D) / (meanLD+mean2D+mean3D);
slopeCL = (1-constCL)/(2*constCL+1);
aL = meanLD-0.4;
aR = meanRD-0.4*slopeCL;
bL = meanLD+0.4;
bR = meanRD+0.4*slopeCL;
plot([aL bL], [aR bR], '--k')
axis equal
axis([1.4 1.7 0.35 0.55]);

if bDoAuxPlots
    % Plot OR-MD vs. all-MD
    figure;
    scatter(testVecMD(:,4),mean(testVecMD(:,1:3),2),50,markerVec{1});
    xLabel('All white matter mean diffusivity ( \mum^2/ms)');
    yLabel('OR mean diffusivity ( \mum^2/ms)');
    axis equal
    axis([0.7 0.9 0.7 0.9]);

    figure;
    scatter(testVecCL(:,4),mean(testVecCL(:,1:3),2),50,markerVec{1});
    xLabel('All white matter linearity');
    yLabel('OR mean linearity');
    axis equal
    axis([0.39 0.44 0.39 0.44]);

    %plot mean and standard error on bar graph
    figure;
    subplot(2,1,1);
    meanVec = [mean(testVec(:,1,1)),mean(testVec(:,2,1)),mean(testVec(:,3,1)),mean(testVec(:,4,1))];
    seVec = [std(testVec(:,1,1)),std(testVec(:,2,1)),std(testVec(:,3,1)),std(testVec(:,4,1))]/sqrt(size(testVec,1));
    bar(1:4,meanVec,0.4);
    hold on;
    errorbar(1:4,meanVec, seVec,'.r');
    set(gca,'XTickLabel',{'Meyer','Central','Direct','All'})
    yLabel('Longitudinal diffusivity ( \mum^2/ms)');
    ylim([1.4 1.6]);

    subplot(2,1,2);
    meanVec = [mean(testVecR(:,1,1)),mean(testVecR(:,2,1)),mean(testVecR(:,3,1)),mean(testVecR(:,4,1))];
    seVec = [std(testVecR(:,1,1)),std(testVecR(:,2,1)),std(testVecR(:,3,1)),std(testVecR(:,4,1))]/sqrt(size(testVecR,1));
    bar(1:4,meanVec,0.4);
    hold on;
    errorbar(1:4,meanVec, seVec,'.r');
    set(gca,'XTickLabel',{'Meyer','Central','Direct','All'})
    xLabel('Fiber Group');
    yLabel('Radial diffusivity ( \mum^2/ms)');
    ylim([0.3 0.5]);

    longVecA = squeeze(testVec(:,4,1));
    radVecA = squeeze(testVecR(:,4,1));
    p = polyfit(longVecA,radVecA,1);
    aL = min(longVecA);
    aR = p(1)*aL + p(2);
    bL = 1.7;
    bR = p(1)*bL + p(2);
    plot([aL bL], [aR bR]);

    longVecOR = reshape(testVec(:,1:3,1),size(testVec,1)*3,1);
    radVecOR = reshape(testVecR(:,1:3,1),size(testVecR,1)*3,1);
    p = polyfit(longVecOR,radVecOR,1);
    aL = min(longVecA);
    aR = p(1)*aL + p(2);
    bL = 1.7;
    bR = p(1)*bL + p(2);
    plot([aL bL], [aR bR]);

    % Plot many linearities
    figure;
    clVec = 0.3:0.05:0.6;
    longVec = 0:0.01:3;
    hold on;
    for pp=1:length(clVec)
        radVec = (1-clVec(pp))*longVec/(2*clVec(pp)+1);
        plot(longVec,radVec);
    end

    aL = 1.45;
    aR = 0.4;
    constCL = 1.05/(1.45+0.8);
    bL = 1.7;
    bR = 1.7 - constCL*(1.45+0.8);
    plot([aL bL], [aR bR], 'r');
    constCL_L = [1.4:0.01:1.7];
    constCL_R = (1-0.47)*constCL_L/(2*0.47+1);
    plot(constCL_L,constCL_R,'g')
end

return;


function displayDValues(ldPool,rdPool,clPool)
%Plot diffusivity parameters vs. clThresh
ldMeans = [];
ldStds = [];
rdMeans = [];
rdStds = [];
clList = [];
clSizes = [];
for cc=0.25:0.05:1
    clPass = clPool(clPool>cc);
    if length(clPass) < 10
        break;
    end
    ldMeans(end+1) = mean(ldPool(clPool>cc));
    ldStds(end+1) = std(ldPool(clPool>cc));
    rdMeans(end+1) = mean(rdPool(clPool>cc));
    rdStds(end+1) = std(rdPool(clPool>cc));
    clList(end+1) = cc;
    clSizes(end+1) = length(clPass);
end

figure;
subplot(2,2,1); plot(clList,ldMeans); 
subplot(2,2,2); plot(clList,ldStds,'r');
subplot(2,2,3); plot(clList,rdMeans); 
subplot(2,2,4); plot(clList,rdStds,'r');
%figure; plot(clList,clSizes);

return;

