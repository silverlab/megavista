% rd_normalizeCenterOfMass.m

%% setup
hemi = 2;

prop = .8;
mapName = 'betaP';

plotFigs = 1;
saveAnalysis = 1;
saveFigs = 1;

%% colors
MCol = [220 20 60]./255; % red
PCol = [0 0 205]./255; % medium blue
nullCol = [0 0 0]; % black
switch mapName
    case 'betaM-P'
        colors = {MCol, PCol};
    case 'betaM'
        colors = {MCol, nullCol};
    case 'betaP'
        colors = {PCol, nullCol};
    otherwise
        error('mapName not recognized')
end
for iCol = 1:numel(colors)
    hsvCol = rgb2hsv(colors{iCol});
    lightColors{iCol} = hsv2rgb([hsvCol(1) .1 1]);
end
if all(colors{2}==[0 0 0])
    lightColors{2}=[.9 .9 .9];
end

%% file i/o
fileBase = sprintf('lgnROI%d', hemi);
comFile = dir(sprintf('%s_centerOfMass_%s_prop%d*',fileBase, mapName, round(prop*100)));
multiVoxFile = sprintf('%s_multiVoxFigData', fileBase);

analysisFile = sprintf('%s_centerOfMassNorm_%s_prop%d_%s',...
    fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
figFile = sprintf('%sScatter_comNormXZ_%s_prop%d_%s',...
    fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));

if numel(comFile)~=1
    error('Too many or too few files matching comFile')
end

%% load data
load(comFile.name)
load(multiVoxFile)

%% get centers info
coords = figData.coordsInplane; % coordsInplane are in epi space

centers{1} = C.centers1;
centers{2} = C.centers2;
varThreshs = C.varThreshs;
nSuperthreshVox = C.nSuperthreshVox;
nThreshs = length(varThreshs);
nCenters = numel(centers);

%% normalize centers
coordsMin = min(coords,[],2);
coordsRange = range(coords,2);

coordsMinMat = repmat(coordsMin',nThreshs,1);
coordsRangeMat = repmat(coordsRange',nThreshs,1);

for iC = 1:nCenters
    centersNorm{iC} = (centers{iC} - coordsMinMat)./coordsRangeMat;
end

%% save analysis
if saveAnalysis
    save(analysisFile, 'C', 'centers', 'centersNorm')
end

%% plot figs
if plotFigs
    f = figure;
    hold on
    for iC = 1:nCenters
        p1(iC) = scatter(centersNorm{iC}(:,1), centersNorm{iC}(:,3), nSuperthreshVox);
        set(p1(iC), 'MarkerEdgeColor', colors{iC}, ...
            'MarkerFaceColor', lightColors{iC}, ...
            'LineWidth', 1)
    end
    xlim([0 1])
    ylim([0 1])
    xlabel('L-R center (normalized)')
    ylabel('V-D center (normalized)')
    title(sprintf('Hemi %d, %s, prop %.1f\nsize = number of voxels', hemi, mapName, prop))
end

%% save figs
if saveFigs
    print(f, '-djpeg', sprintf('figures/%s', figFile))
end



