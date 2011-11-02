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

projectName = 'MTproject_clipCcRois_';
baseDir = '/biac3/wandell4/data/reading_longitude/';
logDir = fullfile(baseDir, 'MT_Project','logs');
dtiYr = {'dti_y1'};%,'dti_y2','dti_y3','dti_y4'};
dtDir = 'dti06';
subs = {'mh0'};
% subs = {'ao0','am0','bg0','crb0','ctb0','da0','es0','hy0','js0','jt0','kj0','ks0',...
%     'lg0','lj0','mb0','md0','mh0','mho0','mm0','nf0','pt0','rh0','rs0','sg0',...
%     'sl0','sy0','tk0','tv0','vh0','vr0'};

%subs = {'md0'};



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
            dt6Dir = fullfile(subDir, dtDir);
            dt6 = fullfile(dt6Dir, 'dt6.mat');
            if exist(dt6) % Only continue if there is a dt6.mat for this subject. Else L110.
                roiDir = fullfile(dt6Dir,'ROIs');
                if ~exist(roiDir), mkdir(roiDir); disp('Created ROIs dir'); end

                % If there is not a CC.mat ROI one will be created and saved in roiDir.
                if ~exist(fullfile(roiDir,'CC.mat'));
                    disp('Finding CC...');
                    dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));
                    ccCoords = dtiFindCallosum(dt.dt6,dt.b0,dt.xformToAcpc);
                    ccRoi = dtiNewRoi('CC','c',ccCoords);
                    dtiWriteRoi(ccRoi, fullfile(roiDir,'CC.mat'));
                    disp(['Writing ' ccRoi.name ' to ' roiDir]);
                    fprintf(fid,'\nNo CC.mat was found for %s. One was created and saved to %s \n',sub.name,roiDir);
                end

                origCC = fullfile(roiDir,'CC.mat');
                clippedCC = fullfile(roiDir,'MT', 'CC_clipMid.mat');
                leftCC = fullfile(roiDir, 'MT', 'CC_clipLeft.mat');
                rightCC = fullfile(roiDir, 'MT', 'CC_clipRight.mat');

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





