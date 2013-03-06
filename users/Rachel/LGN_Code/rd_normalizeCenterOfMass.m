function rd_normalizeCenterOfMass(hemi, mapName, coordsType, talNoScale)
% rd_normalizeCenterOfMass(hemi, mapName, [coordsType],[talNoScale])
%
% hemi is 1 or 2 (left or right)
% mapName is 'betaM-P','betaM', or 'betaP'

%% setup
% hemi = 2;

% mapName = 'betaP';

if notDefined('coordsType')
    coordsType = 'Epi'; % 'Epi', 'Volume', or 'Talairach'
end
if notDefined('talNoScale')
    talNoScale = 0; % 0 for standard Tal coords, 1 for the non-stretched/scaled version
end
fprintf('\n%s coordinates\n', coordsType)

switch mapName
    case 'betaM-P'
        prop = 0.2;
    case 'betaM'
        prop = 0.2;
    case 'betaP'
        prop = 0.8;
    otherwise
        error ('mapName not recognized when setting prop')
end

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
multiVoxFile = sprintf('%s_multiVoxFigData', fileBase);
switch coordsType
    case 'Epi'
        comFile = dir(sprintf('%s_centerOfMass_%s_prop%d*',fileBase, mapName, round(prop*100)));
        analysisFile = sprintf('%s_centerOfMassNorm_%s_prop%d_%s',...
            fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
        figFile{1} = sprintf('%sScatter_comXZ_%s_prop%d_%s',...
            fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
        figFile{2} = sprintf('%sScatter_comNormXZ_%s_prop%d_%s',...
            fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
    case 'Volume'
        comFile = dir(sprintf('%s_centerOfMassVol_%s_prop%d*',fileBase, mapName, round(prop*100)));
        analysisFile = sprintf('%s_centerOfMassVolNorm_%s_prop%d_%s',...
            fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
        figFile{1} = sprintf('%sScatter_comVolXZ_%s_prop%d_%s',...
            fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
        figFile{2} = sprintf('%sScatter_comVolNormXZ_%s_prop%d_%s',...
            fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
    case 'Talairach'
        if talNoScale
            comFile = dir(sprintf('%s_centerOfMassTal_%s_prop%d*',fileBase, mapName, round(prop*100)));
            analysisFile = sprintf('%s_centerOfMassTalNoScaleNorm_%s_prop%d_%s',...
                fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
            figFile{1} = sprintf('%sScatter_comTalNoScaleXZ_%s_prop%d_%s',...
                fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
            figFile{2} = sprintf('%sScatter_comTalNoScaleNormXZ_%s_prop%d_%s',...
                fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
        else
            comFile = dir(sprintf('%s_centerOfMassTal_%s_prop%d*',fileBase, mapName, round(prop*100)));
            analysisFile = sprintf('%s_centerOfMassTalNorm_%s_prop%d_%s',...
                fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
            figFile{1} = sprintf('%sScatter_comTalXZ_%s_prop%d_%s',...
                fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
            figFile{2} = sprintf('%sScatter_comTalNormXZ_%s_prop%d_%s',...
                fileBase, mapName, round(prop*100), datestr(now,'yyyymmdd'));
        end
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
    case {'Volume', 'Talairach'}
        load('../../mrSESSION','mrSESSION')
        ipVoxSize = mrSESSION.inplanes.voxelSize;
        volVoxSize = [1 1 1];
        xform = mrSESSION.alignment;
        % Find volume ROI coordinates - convert from Inplane to Volume
        coordsTemp = xformROIcoords(figData.coordsAnatomy, xform, ipVoxSize, ...
            volVoxSize); % coordsAnatomy are in inplane (gems) space
        % Now refine coords for either the Volume or Talairach case
        switch coordsType
            case 'Volume'
                % For Vol coords, need to switch axi and sag dimensions and need to
                % flip the A-P and D-V directions to make it match the epi coords
                % (and what the plots expect)
                coords(1,:) = coordsTemp(3,:); % Sag --> x
                coords(2,:) = coordsTemp(2,:)*(-1); % Cor --> y, flip A-P --> P-A
                coords(3,:) = coordsTemp(1,:)*(-1); % Axi --> z, flip D-V --> V-D
            case 'Talairach'
                % Get the Talairach xform
%                 talairach = loadTalairachXform(mrSESSION.subject,[],0,1);
                talairach = load('../../vAnatomy_talairach');
                % Convert the Volume coords to Talairach
                [coordsTal coordsNoScale] = rd_volToTalairach(coordsTemp', ...
                    talairach.vol2Tal);
                % Choose either the standard Tal coords, or those without
                % stretching/scaling
                if talNoScale
                    coords = coordsNoScale'; % back to 3 x nvox
                else
                    coords = coordsTal';
                end
        end
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
        % For Vol centers, need to switch axi and sag dimensions and flip
        % A-P and D-V directions
        for iC = 1:numel(centersTemp)
            centers{iC}(:,1) = centersTemp{iC}(:,3); % Sag --> x
            centers{iC}(:,2) = centersTemp{iC}(:,2)*(-1); % Cor --> y, flip A-P --> P-A
            centers{iC}(:,3) = centersTemp{iC}(:,1)*(-1); % Axi --> z, flip D-V --> V-D
        end
    case 'Talairach'
        if talNoScale
            centers{1} = C.centers1TalNoScale;
            centers{2} = C.centers2TalNoScale;
        else
            centers{1} = C.centers1Tal;
            centers{2} = C.centers2Tal;
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
    save(analysisFile, 'coordsType', 'C', 'coords', 'centers', 'centersNorm')
end

%% plot figs
if talNoScale
    extra = '(not scaled)';
else
    extra = '';
end

if plotFigs
    % centers (raw)
    f(1) = figure;
    hold on
    for iC = 1:nCenters
        p1(iC) = scatter(centers{iC}(:,1), centers{iC}(:,3), nSuperthreshVox);
        set(p1(iC), 'MarkerEdgeColor', colors{iC}, ...
            'MarkerFaceColor', lightColors{iC}, ...
            'LineWidth', 1)
    end
%     xlim([0 1])
%     ylim([0 1])
    axis equal
    xlabel('L-R center (coord)')
    ylabel('V-D center (coord)')
    title(sprintf('Hemi %d, %s, prop %.1f, %s coords %s\nsize = number of voxels', hemi, mapName, prop, coordsType, extra))

    % centers (normalized)
    f(2) = figure;
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
    title(sprintf('Hemi %d, %s, prop %.1f, %s coords %s\nsize = number of voxels', hemi, mapName, prop, coordsType, extra))
end

%% save figs
if saveFigs
    for iF = 1:numel(f);
        print(f(iF), '-djpeg', sprintf('figures/%s', figFile{iF}))
    end
end



