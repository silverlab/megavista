function rd_normalizeCenterOfMass(hemi, mapName)
% rd_normalizeCenterOfMass(hemi, mapName)
%
% hemi is 1 or 2 (left or right)
% mapName is 'betaM-P','betaM', or 'betaP'

%% setup
% hemi = 2;

% mapName = 'betaP';

coordsType = 'Volume'; % 'Epi' or 'Volume'

switch mapName
    case 'betaM-P'
        prop = 0.2;
    case 'betaM'
        prop = 0.2;
    case 'betaP'
        prop = 0.8;
    otherwise
        error ('mapName not recognized when setting prop and betaCoefs')
end

plotFigs = 1;
saveAnalysis = 0;
saveFigs = 0;

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
multiVoxFile = sprintf('%s_multiVoxFigData', fileBase);
switch coordsType
    case 'Epi'
        comFile = dir(sprintf('%s_centerOfMass_%s_prop%d*',fileBase, mapName, round(prop*100)));
        analysisFile = sprintf('%s_centerOfMassNorm_%s_prop%d_%s',...
            fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
        figFile = sprintf('%sScatter_comNormXZ_%s_prop%d_%s',...
            fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
    case 'Volume'
        comFile = dir(sprintf('%s_centerOfMassVol_%s_prop%d*',fileBase, mapName, round(prop*100)));
        analysisFile = sprintf('%s_centerOfMassVolNorm_%s_prop%d_%s',...
            fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
        figFile = sprintf('%sScatter_comVolNormXZ_%s_prop%d_%s',...
            fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
    otherwise
        error('coordsType not recognized.')
end

if numel(comFile)~=1
    error('Too many or too few files matching comFile')
end

%% load data
load(comFile.name)
load(multiVoxFile)

%% get roi coords
switch coordsType
    case 'Epi'
        coords = figData.coordsInplane; % coordsInplane are in epi space
    case 'Volume'
        load('../../mrSESSION','mrSESSION')
        ipVoxSize = mrSESSION.inplanes.voxelSize;
        volVoxSize = [1 1 1];
        xform = mrSESSION.alignment;
        % find volume ROI coordinates - convert from inplane to volume
        coordsTemp = xformROIcoords(figData.coordsAnatomy, xform, ipVoxSize, ...
            volVoxSize); % coordsAnatomy are in inplane (gems) space
        % For Vol coords, need to switch axi and sag dimensions and need to
        % flip the A-P and D-V directions
        coords(1,:) = coordsTemp(3,:); % Sag --> x
        coords(2,:) = coordsTemp(2,:)*(-1); % Cor --> y, flip A-P
        coords(3,:) = coordsTemp(1,:)*(-1); % Axi --> z, flip D-V
    otherwise
        error('coordsType not recognized.')
end

%% get centers info
switch coordsType
    case 'Epi'
        centers{1} = C.centers1;
        centers{2} = C.centers2;
    case 'Volume'
        centersTemp{1} = C.centers1Vol;
        centersTemp{2} = C.centers2Vol;
        % For Vol centers, need to switch axi and sag dimensions
        for iC = 1:numel(centersTemp)
            centers{iC}(:,1) = centersTemp{iC}(:,3); % Sag --> x
            centers{iC}(:,2) = centersTemp{iC}(:,2)*(-1); % Cor --> y, flip A-P
            centers{iC}(:,3) = centersTemp{iC}(:,1)*(-1); % Axi --> z, flip D-V
        end
    otherwise
        error('coordsType not recognized.')
end
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
    save(analysisFile, 'C', 'coords', 'centers', 'centersNorm')
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
    title(sprintf('Hemi %d, %s, prop %.1f, %s coords\nsize = number of voxels', hemi, mapName, prop, coordsType))
end

%% save figs
if saveFigs
    print(f, '-djpeg', sprintf('figures/%s', figFile))
end



