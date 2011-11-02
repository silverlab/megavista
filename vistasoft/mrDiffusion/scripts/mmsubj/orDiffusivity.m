%Script: orDiffusivity
%        Analyze statistics on the optic radiation bundles
%
% The OR Stats files were created using ctrComputeStatsORBundles
% The scripts for the mmORStats and controlORStats were created using the
% mmStatsFile in the analysisScripts directory
%
% History:  This is derived from dispStatsOR - from Tony Sherbondy
%

%% Read in information about the control subjects
% On August 13 the data were stored in /teal/scr1/dti/or
% wDir = '/teal/scr1/dti/or';
% statsFile = 'evStats';   % This is created using the ctrCompStatsORBundles.m routine
% evStats = load(fullfile(wDir,statsFile));
%
% We copied the control statistics to a file on brian's directory and
% renamed it 'controlORStats.mat'
%
% We also made a copy of the summary statistics of all the OR data in
% 'Y:\data\DTI_Blind\stats' 
% We mapped Y: to '\\white.stanford.edu\biac3-wandell4'


%% Notes - useful routines
% foo{1}   =  dtiReadFibers
% mergedFG = dtiMergeFiberGroups(fg1,fg2,name)
%

%% Average the control subjects 
wDir ='Y:\data\DTI_Blind\stats';
statsFile = 'controlORStatsAll.mat';
evStats = load(fullfile(wDir,statsFile));

% Average the two hemispheres and the OR paths for the 8 subjects
longitudinal    = zeros(8,2);
radial          = zeros(8,2);
fractAnisotropy = zeros(8,2);
clThresh        = 0;   

for ii=[1,2,3,4,5,6,7,8]   % Each subject
    for hh=1:2   %Each hemisphere

        % The data are stored as both left and right
        eigVal = cell2mat(evStats.stats(ii,hh));   % Merged statistics
        if ii == 5  % Too many points for my little laptop
            n = size(eigVal,1);
            s = round(rand(500000,1)*n);
            eigVal = eigVal(s,:);
        end
        
        cl = dtiComputeWestinShapes(eigVal);
        fa = dtiComputeFA(eigVal);

        % Get the longitudinal and radial diffusivities for each subject,
        % and each hemisphere.  We choose only the voxels that have a
        % linearity threshold within the OR.

        lst = (cl > clThresh);
        fprintf('Subject %d (hemi %d): %d (nNodes)\n',ii,hh,length(lst));
        longitudinal(ii,hh) = mean(eigVal(lst,1));
        radial(ii,hh)  = mean((eigVal(lst,2) + eigVal(lst,3))*0.5);
        fractAnisotropy(ii,hh) = mean(fa(lst));

    end
end

% We have to deal with this subject (#5) who has too many points
% longitudinal(5,1) = longitudinal(4,1);
% longitudinal(5,2) = longitudinal(4,2);
% radial(5,1) = radial(4,1);
% radial(5,2) = radial(4,2);

% The longitudinal and radial diffusivities of the controls in real
% units.  The left/right is determined by the order of files that we
% compute in ctrCompStatsORBundles.  We did this in left-right order.  So,
% the red symbols are (unfortunately) left.  We should probably go through
% all of this and make red-right.
figure;
plot(longitudinal(:,1),radial(:,1),'ro');hold on
plot(longitudinal(:,2),radial(:,2),'bo');hold off
xlabel('Longitudinal diffusivity');
ylabel('Radial diffusivity');
axis equal
set(gca,'xlim',[1.2 1.6],'ylim',[0.3 0.8])
grid on

% We normalize the diffusivities by the mean diffusivity of the
% population
% mL = mean(longitudinal(:));
% mR = mean(radial(:));

% Make a normalized graph, used in Tony's OR paper
% for ii=1:8
%     plot(longitudinal(ii,1:2)/mL,radial(ii,1:2)/mR,'-o')
%     hold on
%     plot(longitudinal(ii,2)/mL,radial(ii,2)/mR,'ro')
%     hold on
% end
% xlabel('Longitudinal diffusivity (normalized)');
% ylabel('Radial diffusivity (normalized)');
% hold off
% 
% mean(longitudinal(:,1) - longitudinal(:,2)) / mean(longitudinal(:))
% mean(radial(:,1) - radial(:,2)) / mean(radial(:))
% 
% axis equal
% grid on
% xlabel('Longitudinal diffusivity');
% ylabel('Radial diffusivity');
% set(gca,'xlim',[0.85 1.15],'ylim',[0.85 1.15])
% 
% title(sprintf('Pooled OR, clThresh = %.02f',clThresh));
% uData.longitudinal = longitudinal;
% uData.radial = radial;
% uData.cmd = 'plot(longitudinal,radial,''o'',mean(mmL),mean(mmR),''gs'')';
% set(gcf,'userdata',uData);

% save ORdata longitudinal radial mmL mmR


%% Create MM scatter plot for longitudinal vs. radial diffusivity averages

% This term is a cell array that contains the eigenvalues for all of the
% subjects separated by hemisphere and path. Thus, stats(3,2,2) is subject
% 3, right hemisphere, central path

% The file was created using the checked-in code ctrCompoStatsORBundles.
% That routine was used both for the controls and for MM.
tmp = load('mmORStats.mat');

% Should be the same as the global one normally.  Here if you want to
% change it.
% clThresh = 0.3;
mmL  = zeros(2,1);
mmR  = zeros(2,1);
mmFA = zeros(2,1);

for hh=1:2  % Right and left hemisphere
    eigVal = tmp.stats{hh};
    fprintf('Subject MM (hemi %d): %d (nFibers)\n',hh,size(eigVal,1));
    cl = dtiComputeWestinShapes(eigVal);
    [fa,md,rd] = dtiComputeFA(eigVal);

    loThresh = eigVal((cl>clThresh),1);
    rdThresh = rd(cl > clThresh);
    faThresh = fa(cl > clThresh);
    % figure; plot(loThresh,rdThresh,'.')

    % For a 0.3 linear threshold the MM values are 1.5028 and 0.4397
    mmL(hh)  = mean(loThresh);
    mmR(hh)  = mean(rdThresh);
    mmFA(hh) = mean(faThresh);
end

% Mike's pattern is the same as controls
figure;
xyData = [longitudinal(:),radial(:)];
nSD = 2;
covEllipsoid(xyData,nSD,figure); hold on
plot(longitudinal(:,1),radial(:,1),'ko'); hold on
plot(longitudinal(:,2),radial(:,2),'ro'); 
plot(mmL(1),mmR(1),'kS');
plot(mmL(2),mmR(2),'rS');
hold off
xlabel('Longitudinal diffusivity');
ylabel('Radial diffusivity');
grid on

% Set the range ...
mn = min(cat(1,xyData(:,1),mmL(:))); 
mx = max(cat(1,xyData(:,1),mmL(:)));
set(gca,'xlim',[mn*0.9,mx*1.1])
mn = min(cat(1,xyData(:,2),mmR(:))); 
mx = max(cat(1,xyData(:,2),mmR(:)));
set(gca,'ylim',[mn*0.9,mx*1.1])

% Correlation is 0.6 and p< 0.014
[r,p] = corrcoef(xyData);

% Mike's FA is also lower ...
figure;
plot(fractAnisotropy(:,1),'k*'); hold on
plot(fractAnisotropy(:,2),'r*'); 
plot(10,mmFA(1),'ks'); 
plot(10,mmFA(2),'rs');
xlabel('Subject')
ylabel('FA')
set(gca,'ylim',[0.5 0.75])
    
%% AR a one-eyed subject
tmp = load('arORStats.mat');

% Should be the same as the global one normally.  Here if you want to
% change it.
% clThresh = 0.3;
arL  = zeros(2,1);
arR  = zeros(2,1);
arFA = zeros(2,1);

for hh=1:2  % Right and left hemisphere
    eigVal = tmp.stats{hh};
    cl = dtiComputeWestinShapes(eigVal);
    [fa,md,rd] = dtiComputeFA(eigVal);

    loThresh = eigVal((cl>clThresh),1);
    rdThresh = rd(cl > clThresh);
    faThresh = fa(cl > clThresh);
    % figure; plot(loThresh,rdThresh,'.')

    % For a 0.3 linear threshold the dl values are 1.5028 and 0.4397
    arL(hh)  = mean(loThresh);
    arR(hh)  = mean(rdThresh);
    arFA(hh) = mean(faThresh);
end

% AR's pattern is the same as controls
figure;
plot(longitudinal(:,1),radial(:,1),'ro'); hold on
plot(longitudinal(:,2),radial(:,2),'bo');
plot(arL(1),arR(1),'ro','markerfacecolor','r');
plot(arL(2),arR(2),'bo','markerfacecolor','b');
hold off
xlabel('Longitudinal diffusivity');
ylabel('Radial diffusivity');
axis equal

figure(2);
l = mean(longitudinal,2);
r = mean (radial,2);
plot(l,r,'o')
hold on;
plot((arL(1) + arL(2))/2, (arR(1)+arR(2))/2,'ro','markerfacecolor','r');
plot((mmL(1) + mmL(2))/2, (mmR(1)+mmR(2))/2,'co','markerfacecolor','c');
hold off
xlabel('Longitudinal diffusivity');
ylabel('Radial diffusivity');
axis equal

%% MS a one-eyed subject
tmp = load('msORStats.mat');

% Should be the same as the global one normally.  Here if you want to
% change it.
% clThresh = 0.3;
msL  = zeros(2,1);
msR  = zeros(2,1);
msFA = zeros(2,1);

for hh=1:2  % Right and left hemisphere
    eigVal = tmp.stats{hh};
    cl = dtiComputeWestinShapes(eigVal);
    [fa,md,rd] = dtiComputeFA(eigVal);

    loThresh = eigVal((cl>clThresh),1);
    rdThresh = rd(cl > clThresh);
    faThresh = fa(cl > clThresh);
    % figure; plot(loThresh,rdThresh,'.')

    % For a 0.3 linear threshold the dl values are 1.5028 and 0.4397
    msL(hh)  = mean(loThresh);
    msR(hh)  = mean(rdThresh);
    msFA(hh) = mean(faThresh);
end

% MS's pattern is the same as controls
figure;
plot(longitudinal(:,1),radial(:,1),'ro'); hold on
plot(longitudinal(:,2),radial(:,2),'bo');
plot(msL(1),msR(1),'ro','markerfacecolor','r');
plot(msL(2),msR(2),'bo','markerfacecolor','b');
xlabel('Longitudinal diffusivity');
ylabel('Radial diffusivity');

figure(2);
l = mean(longitudinal,2);
r = mean (radial,2);
plot(l,r,'o')
hold on;
plot((arL(1) + arL(2))/2, (arR(1)+arR(2))/2,'ro','markerfacecolor','r');
plot((mmL(1) + mmL(2))/2, (mmR(1)+mmR(2))/2,'co','markerfacecolor','c');
plot((msL(1) + msL(2))/2, (msR(1)+msR(2))/2,'co','markerfacecolor','g');
hold off
xlabel('Longitudinal diffusivity');
ylabel('Radial diffusivity');

figure;
plot(longitudinal(:,1),radial(:,1),'ro');hold on
plot(longitudinal(:,2),radial(:,2),'bo');
xlabel('Longitudinal diffusivity');
ylabel('Radial diffusivity');
hold on
plot(arL(1), arR(1),'rs','markerfacecolor','r');
plot(arL(2), arR(2),'bs','markerfacecolor','b');
plot(msL(1), msR(1),'r*','markerfacecolor','r');
plot(msL(2), msR(2),'b*','markerfacecolor','b');
plot(mmL(1), mmR(1),'rd','markerfacecolor','r');
plot(mmL(2), mmR(2),'bd','markerfacecolor','b');
grid on
% set(gca,'xlim',[1.2 1.6],'ylim',[0.3 0.8])

figure;
nSD = 2;
covEllipsoid(xyData,nSD,figure); hold on
hold on;
plot(arL, arR,'rs','markerfacecolor','r');
plot(mmL, mmR,'co','markerfacecolor','c');
plot(msL, msR,'go','markerfacecolor','g');
grid on
% Set the range
% mn = min(cat(1,xyData(:,1),mmL(:))); 
% mx = max(cat(1,xyData(:,1),mmL(:)));
% mn = min(cat(1,xyData(:,2),mmR(:))); 
% mx = max(cat(1,xyData(:,2),mmR(:)));

%% WG a blind subject
tmp = load('wgORStats.mat');

% Should be the same as the global one normally.  Here if you want to
% change it.
% clThresh = 0.3;
wgL  = zeros(2,1);
wgR  = zeros(2,1);
wgFA = zeros(2,1);

for hh=1:2  % Right and left hemisphere
    eigVal = tmp.stats{hh};
    cl = dtiComputeWestinShapes(eigVal);
    [fa,md,rd] = dtiComputeFA(eigVal);

    loThresh = eigVal((cl>clThresh),1);
    rdThresh = rd(cl > clThresh);
    faThresh = fa(cl > clThresh);
    % figure; plot(loThresh,rdThresh,'.')

    % For a 0.3 linear threshold the dl values are 1.5028 and 0.4397
    wgL(hh)  = mean(loThresh);
    wgR(hh)  = mean(rdThresh);
    wgFA(hh) = mean(faThresh);
end

% wg's pattern 
figure(1);
plot(longitudinal(:,1),radial(:,1),'ro'); hold on
plot(longitudinal(:,2),radial(:,2),'bo');
plot(wgL(1),wgR(1),'ro','markerfacecolor','r');
plot(wgL(2),wgR(2),'bo','markerfacecolor','b');
hold off
xlabel('Longitudinal diffusivity');
ylabel('Radial diffusivity');

l = mean(longitudinal,2);
r = mean (radial,2);
ell = covEllipsoid([l,r],nSD); 
plot(l,r,'o'); hold on
plot(ell(:,1),ell(:,2),'--')
hold on;
plot((arL(1) + arL(2))/2, (arR(1)+arR(2))/2,'ro','markerfacecolor','r');
plot((mmL(1) + mmL(2))/2, (mmR(1)+mmR(2))/2,'co','markerfacecolor','c');
plot((msL(1) + msL(2))/2, (msR(1)+msR(2))/2,'go','markerfacecolor','g');
plot((wgL(1) + wgL(2))/2, (wgR(1)+wgR(2))/2,'bo','markerfacecolor','b');
hold off
xlabel('Longitudinal diffusivity');
ylabel('Radial diffusivity');
grid on
set(gca,'xlim',[1.15 1.5],'ylim',[0.45 0.85])
[r,p] = corrcoef([l,r]);

figure;
plot(longitudinal(:,1),radial(:,1),'ro');hold on
plot(longitudinal(:,2),radial(:,2),'bo');hold off
xlabel('Longitudinal diffusivity');
ylabel('Radial diffusivity');
hold on
plot(arL(1), arR(1),'rs','markerfacecolor','r');
plot(arL(2), arR(2),'bs','markerfacecolor','b');
plot(msL(1), msR(1),'r*','markerfacecolor','r');
plot(msL(2), msR(2),'b*','markerfacecolor','b');
plot(mmL(1), mmR(1),'rd','markerfacecolor','r');
plot(mmL(2), mmR(2),'bd','markerfacecolor','b');
plot(wgL(1), wgR(1),'r+','markerfacecolor','r');
plot(wgL(2), wgR(2),'b+','markerfacecolor','b');
grid on
% set(gca,'xlim',[1.1 1.6],'ylim',[0.3 0.8])

figure; nSD = 2;
covEllipsoid(xyData,nSD,figure); hold on

hold on;
plot(arL, arR,'rs','markerfacecolor','r');
plot(mmL, mmR,'co','markerfacecolor','c');
plot(msL, msR,'go','markerfacecolor','g');
plot(wgL, wgR,'b+','markerfacecolor','b');
grid on

% Set the range
mn = min(cat(1,xyData(:,1),mmL(:))); 
mx = max(cat(1,xyData(:,1),mmL(:)));
mn = min(cat(1,xyData(:,2),mmR(:))); 
mx = max(cat(1,xyData(:,2),mmR(:)));


%% This is the achiasmic subject, DL, not really relevant here.
tmp = load('dlORStats.mat');

% Should be the same as the global one normally.  Here if you want to
% change it.
% clThresh = 0.3;
dlL  = zeros(2,1);
dlR  = zeros(2,1);
dlFA = zeros(2,1);

for hh=1:2  % Right and left hemisphere
    eigVal = tmp.stats{hh};
    cl = dtiComputeWestinShapes(eigVal);
    [fa,md,rd] = dtiComputeFA(eigVal);

    loThresh = eigVal((cl>clThresh),1);
    rdThresh = rd(cl > clThresh);
    faThresh = fa(cl > clThresh);
    % figure; plot(loThresh,rdThresh,'.')

    % For a 0.3 linear threshold the dl values are 1.5028 and 0.4397
    dlL(hh)  = mean(loThresh);
    dlR(hh)  = mean(rdThresh);
    dlFA(hh) = mean(faThresh);
end

% DL's pattern is the same as controls
figure(1);
plot(longitudinal(:,1),radial(:,1),'ro');
hold on
plot(longitudinal(:,2),radial(:,2),'bo');
plot(dlL(1),dlR(1),'ro','markerfacecolor','r');
plot(dlL(2),dlR(2),'bo','markerfacecolor','b');
hold off
xlabel('Longitudinal diffusivity');
ylabel('Radial diffusivity');
axis equal

figure(2);
l = mean(longitudinal,2);
r =mean (radial,2);
plot(l,r,'o')
hold on;
plot((dlL(1)+dlL(2))/2, (dlR(1)+dlR(2))/2,'ro','markerfacecolor','r');
hold off
xlabel('Longitudinal diffusivity');
ylabel('Radial diffusivity');
axis equal
