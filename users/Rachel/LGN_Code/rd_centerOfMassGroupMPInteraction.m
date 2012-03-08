% rd_centerOfMassGroupMPInteraction

%% setup
MCol = [220 20 60]./255; % red
PCol = [0 0 205]./255; % medium blue
colors = {MCol, PCol};

%% load data
m = load('groupCenterOfMass_7T_N4_betaM_prop50_20120304');
p = load('groupCenterOfMass_7T_N4_betaP_prop50_20120304');

nSubjects = numel(m.subjects);
varThreshs = m.groupMean.varThreshs(:,1);
nVox = m.groupData.nSuperthreshVox;

%% M centers z
m.centers1z = squeeze(m.groupData.centers1(:,3,:,:)); % [thresh x sub x hemi]
m.centers2z = squeeze(m.groupData.centers2(:,3,:,:));

% if 'more M' is more ventral, these differences should be negative
m.centersDiff = m.centers1z - m.centers2z;

%% P centers z
p.centers1z = squeeze(p.groupData.centers1(:,3,:,:)); % [thresh x sub x hemi]
p.centers2z = squeeze(p.groupData.centers2(:,3,:,:));

% if 'more P' is more dorsal, these differences should be positive
p.centersDiff = p.centers1z - p.centers2z;

%% Plot
%% scatter plot
cmap = colormap(lines);
xbound = max(abs(m.centersDiff(:)));
ybound = max(abs(p.centersDiff(:)));

f1 = figure;
for hemi = 1:2
    subplot(1,2,hemi)
    hold on
    plot([-xbound xbound],[0 0],'k')
    plot([0 0],[-ybound ybound],'k')
    
    for iSubject = 1:nSubjects
        %     scatter(m.centersDiff(:,iSubject,hemi), p.centersDiff(:,iSubject,hemi),...
        %         (varThreshs*8000)+1, cmap(iSubject,:),'filled')
        scatter(m.centersDiff(:,iSubject,hemi), p.centersDiff(:,iSubject,hemi),...
            nVox(:,iSubject,hemi), cmap(iSubject,:),'filled')
    end
    xlabel('more M relative center (V<-->D)')
    ylabel('more P relative center (V<-->D)')
%     title(sprintf('hemi %d, %s, prop %.01f', hemi, m.mapName, m.prop))
    title(sprintf('hemi %d', hemi))
    axis tight
    axis square
end
rd_supertitle(sprintf('%s N=%d, %s, prop %.01f', ...
    m.scanner, nSubjects, m.mapName, m.prop))

%% interaction bar plot
f2 = figure;
mzdiff0 = squeeze(m.centersDiff(1,:,:));
pzdiff0 = squeeze(p.centersDiff(1,:,:));
bar([mzdiff0(:) pzdiff0(:)])
colormap([colors{1}; colors{2}])
xlabel('hemisphere')
ylabel('center of mass (V<-->D)')
title(sprintf('%s N=%d, beta prop %.01f, all voxels', m.scanner, nSubjects, m.prop))
legend('M relative center', 'P relative center','Location','Best')

%% mp comparison bar plot
f3 = figure;
mzcenters1z0 = squeeze(m.centers1z(1,:,:));
pzcenters1z0 = squeeze(p.centers1z(1,:,:));
bar([mzcenters1z0(:) pzcenters1z0(:)])
colormap([colors{1}; colors{2}])
xlabel('hemisphere')
ylabel('center of mass (V<-->D)')
title(sprintf('%s N=%d, beta prop %.01f, all voxels', m.scanner, nSubjects, m.prop))
legend('high betaM group', 'high betaP group','Location','Best')



