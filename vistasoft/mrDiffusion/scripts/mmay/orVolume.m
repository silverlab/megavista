% Script
%  Compute volume of the OR for each of the control subjects in each hemisphere
%  Units are mm^3
%  First we compute these for all of the control subjects.
%  Then we compute this for Michael May.
%  Then we compute this for the achiasmic subject (DL)
%
% Wandell

% chdir('/teal/scr1/dti/or')
% chdir('Y:\dti\or')
subjDirs     = {'aab050307', 'ah051003', 'as050307', 'db061209', 'dla050311','gm050308', 'jy060309', 'me050126'};
orFiles      = {'LOR_merged.mat','ROR_merged.mat'};

%% Control subjects
%
% The control OR data are in separate files.  So we can't use
% dtiFiberVolume.  Instead we need to group the fibers and then calculate.
% That is what happens here.

v = zeros(length(subjDirs),2);

for ii=1:length(subjDirs)
    d = fullfile('Y:\dti\or\',subjDirs{ii},'fibers\conTrack\or_clean')
    chdir(d);
    for hh=1:2
        if ii==5
            v(ii,hh) = v(4,hh);
        else
            v(ii,hh) = dtiFiberVolume(orFiles{hh});
        end
    end
end

% for ii=1:length(subjDirs)
%     for hh=1:2
%         coords = [];
%         for pSeg=1:3
%             fName = fullfile(wDir,subjDirs{ii},'fibers','conTrack','or_clean',pathFiles{hh,pSeg});
%             if ~exist(fName,'file'), error('%s does not exist',fName); end
%            fg = dtiReadFibers(fName);
%            coords = [coords ; unique(round(horzcat(fg.fibers{:})'),'rows')]; 
%         end
%          v(ii,hh) = size(unique(coords,'rows'),1);
%     end
% end


%% Mike May

% When we mount Z: as /biac3/wandell4, then we can change to
% Z:/data/DTI_Blind

chdir('Z:/data/DTI_Blind/mm040325_newPreprocPipeLine/fibers/conTrack/or_clean');

orFiles = {'ltLGN_ltV1_mm_top5000_clean.mat','rtLGN_rtV1_mm_top5000_clean.mat'};

% Allocate space for MM's volume in left and right
mmV = zeros(1,2);
for hh=1:2
    mmV(hh) = dtiFiberVolume(orFiles{hh});
end

%mmV are the OR volumes of  left and right hemisphere (mm^3) in MM
mmV

%% DL

% Change to 
% /biac3/wandell5/data/Achiasma/DL070825_anatomy/fibers/conTrack/or_clean

orFiles = {'LOR_cleaned.mat', 'ROR_cleaned.mat'};

dlV = zeros(1,2);

for hh=1:2
    dlV(hh) = dtiFiberVolume(orFiles{hh});
end


%% Summary volume numbers

figure(1)
plot(v(:,1),v(:,2),'bo')
hold on
plot(dlV(1),dlV(2),'bo','markerfacecolor','b')
axis equal
line([4500 13000],[4500 13000])
xlabel('Left OR volume (mm^3)')
ylabel('Right OR volume (mm^3)')


