% dti_MM_clipCcRois
%
% This script will loop through a group of subjects, load their CC ROI, and
% clip the coordinates such that only the central most slice of the ROI
% will be kept. This is done for use with conTrack. This script will also
% take the CC.mat ROI and divide it into three segments that comprise the
% left, central, and right slices of the CC ROI.
%
% If a CC ROI is not found for that subject one will be created and saved.
% That ROI will then be used for the clipping. 
%
% HISTORY: 2009.02.13 LMP wrote the thing
%



%% Set up directory structure

projectName = 'MM_ClipCCrois';
baseDir = '/biac3/wandell4/data/reading_longitude/';
logDir = fullfile(baseDir, 'dti_adults','ctr_controls','logs');
dtiYr = {'dti_adults'};
dtDir = 'dti06';

% subs = {'aab050307','ah051003','am090121','ams051015','as050307','aw040809','bw040922','ct060309','db061209','dla050311',...
%    'gd040901','gf050826','gm050308','jl040902','jm061209','jy060309','ka040923','mbs040503','me050126','mo061209',...
%    'mod070307','mz040828','pp050208','rfd040630','rk050524','sc060523','sd050527','sn040831','sp050303','tl051015'};
% 
% subs = {'dl070825'};
subs = {'mbs040503'};

%% Start a log text file 

dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
logFile = fullfile(logDir,[projectName,dateAndTime '.txt']);
fid=fopen(logFile,'w');
startTime = clock;

fprintf(fid,'\n************************************************ \n');
fprintf(fid,'Clipping CC ROIs...\n\n');
fprintf('\nWill clip CC ROIs for %d subjects \n\n',length(subs));
fprintf(fid,'\nWill clip CC ROIs for %d subjects... %s \n',length(subs));
fprintf(fid,'Subs: \r');
fprintf(fid, '  %s,', subs{:});
fprintf(fid,'\n************************************************ \n');


%% The Work 

for ii=1:length(subs)
    fprintf(fid,'\n ------------------------------------------ \n');
    % Loop through for each year of dti data
    for jj=1:length(dtiYr)
        sub = dir(fullfile(baseDir,dtiYr{jj},[subs{ii} '*']));
        if ~isempty(sub) % If there is no data for dtiYr{kk}, skip.
            subDir = fullfile(baseDir,dtiYr{jj},sub.name);
            dt6Dir = fullfile(subDir,'dti06');
            dt6 = fullfile(dt6Dir, 'dt6.mat');
            if exist(dt6) % Only continue if there is a dt6.mat for this subject. Else L110.
                roiDir = fullfile(dt6Dir,'ROIs');
                if ~exist(roiDir), mkdir(roiDir); disp('Created ROIs dir'); end

%                 % If there is not a CC.mat ROI one will be created and saved in roiDir.
%                 if ~exist(fullfile(roiDir,'CC.mat'));
%                     disp('Finding CC...');
%                     dt = dtiLoadDt6(dt6);
%                     ccCoords = dtiFindCallosum(dt.dt6,dt.b0,dt.xformToAcpc);
%                     ccRoi = dtiNewRoi('CC','c',ccCoords);
%                     dtiWriteRoi(ccRoi, fullfile(roiDir,'CC.mat'));
%                     disp(['Writing ' ccRoi.name ' to ' roiDir]);
%                     fprintf(fid,'\nNo CC.mat was found for %s. One was created and saved to %s \n',sub.name,roiDir);
%                 end

                origCC = fullfile(roiDir,'CC.mat');
                clippedCC = fullfile(roiDir,'CC_clipMid.mat');
                leftCC = fullfile(roiDir, 'CC_clipLeft.mat');
                rightCC = fullfile(roiDir, 'CC_clipRight.mat');

                origCC = dtiReadRoi(origCC);

                % create and save the central CC plane
                [centerCC roiNot] = dtiRoiClip(origCC, [1 1], [], []);
                [newCC roiNot] = dtiRoiClip(centerCC, [-1 -1], [], []);
                newCC.name = 'CC_clip';
                newCC.color = 'g';

                dtiWriteRoi(newCC, clippedCC);

                % create and save the left CC plane
                [ltCC roiNot] = dtiRoiClip(origCC, [0 1], [], []);
                ltCC.name = 'CC_clipLeft';
                ltCC.color = 'b';

                dtiWriteRoi(ltCC, leftCC);

                % create and save the right CC plane
                [rtCC roiNot] = dtiRoiClip(origCC, [-1 0], [], []);
                rtCC.name = 'CC_clipRight';
                rtCC.color = 'r';

                dtiWriteRoi(rtCC, rightCC);

                % Write to log file
                subCode = sub.name;
                [tmp subCode] = fileparts(subCode);
                fprintf('\nProcessing %s... \n',subCode);
                fprintf(fid,'\nProcessing %s... \n',subCode);
                fprintf(fid,'\n\tOriginal ROI: %s ',(fullfile(roiDir,'CC.mat')));
                disp(sprintf(['\n\tSaved: ', clippedCC]));
                disp(sprintf(['\n\tSaved: ', leftCC]));
                disp(sprintf(['\n\tSaved: ', rightCC]));
                fprintf(fid,'\n\t\tClipped ROI: %s ', clippedCC);
                fprintf(fid,'\n\t\tClipped Left ROI: %s ', leftCC);
                fprintf(fid,'\n\t\tClipped Right ROI: %s \n', rightCC);

            else
                disp(sprintf(['\n No dt6.mat!!! for ' subs{ii} ' in '  dtiYr{jj} '! Skipping.']));
                fprintf(fid,'\n No dt6.mat for %s in %s. Skipping!\n', subs{ii}, dtiYr{jj});
            end
        else
            disp(sprintf(['\n No data for ' subs{ii} ' in '  dtiYr{jj} '! Skipping.']));
            fprintf(fid,'\n No data for %s in %s. Skipping!\n', subs{ii}, dtiYr{jj});
        end

    end
end

fprintf(fid,'\n\n---------End---------\n');
disp('DONE!');

fclose(fid); % Close and save the log file.

return





