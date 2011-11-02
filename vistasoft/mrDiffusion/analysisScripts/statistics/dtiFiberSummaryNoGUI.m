% DTIFIBERSUMMARY
%
% Created to batch script the fiber group analyses normally executed
% through the DTIFIBERUI GUI (Analyze --> Fiber groups --> Summary) -- and
% will also calculate the density volume of the fiber group eventually. It will output
% all these to a struct called SUMMARY. 
%
% Usage: summary = dtiFiberSummary(directories, fibers)
% Example usage in a batch script: see dti_OTS_FiberSummary.m
%
% INPUT 1: Should be a cell array where each cell has the
% full path and file name of the subject's fiber directory where the fiber
% group .mat files can be found. 
% EXAMPLE: dirCellArray{1} = Y:\data\reading_longitude\dti\ad040522\fibers\OTSproject
%
% INPUT 2: Should be a cell array where each cell has the name of the fiber
% group that you want a summary of. 
% EXAMPLE: fiberCellArray = {'LOTS.mat', 'ROTS.mat'};
%
% OUTPUT: A struct with the number of elements corresponding to the number
% of subjects (length of first input argument: S), and fields corresponding to
% the number of fibers (length of second input argument: F). The fiber fields
% will have subfields corresponding to 
% (1) fiber group name
% (2) mean length
% (3) number of fibers
% (4) mean FA
% (5) mean MD
% (6) fiber density volume 
% (7) error messages (NaNs, etc).
% EXAMPLE: summary(S) = 2 x S struct with fields: 
%                                         subject
%                                         fg
% EXAMPLE: summary(S).fiber(F) = 7 x F struct with fields:
%                                         name
%                                         length
%                                         numFibers
%                                         meanFA
%                                         meanMD
%                                         densityVol
%                                         errors
%
% Created by DY, 3/9/2007

function summary = dtiFiberSummaryNoGUI(subjects, fibers)

summary = struct('subject',{},'fg',{}); % intialize SUMMARY

for ii=1:length(subjects)
    if exist(subjects{ii},'dir')
        % Load the subject's dt6 file, and change to the fiber directory
        [dir,name] = fileparts(fileparts(fileparts(subjects{ii}))); % shaves off OTSproject
        disp(['Processing ' name '...']); %displays a string on the screen
        try
            dt = load(fullfile(dir, name, [name '_dt6.mat'])); % y1 dt6 filenames
        catch
            dt = load(fullfile(dir, name, [name '_dt6_noMask.mat'])); % y2 dt6 filenames
        end
        cd(subjects{ii});
        % Fill in SUMMARY: name
        summary(ii).subject = name;
        for jj=1:length(fibers)
            if exist(fibers{jj},'file')
                % Fill in SUMMARY, initialize some values
                summary(ii).fg(jj).name = fibers{jj};
                % Perform the relevant summary analyses
                fg = dtiReadFibers(fibers{jj}); % load fibers                
                stepSize = mean(sqrt(sum(diff(fg.fibers{1},1,2).^2))); % Just measure the first fiber. They *should* all be the same!
                l = cellfun('length',fg.fibers);
                coords = horzcat(fg.fibers{:})';
                dt6 = dtiGetValFromTensors(dt.dt6, coords, inv(dt.xformToAcPc),'dt6','nearest');
                dt6 = dt6(~all(dt6==0,2),:); % Some fibers extend a little beyond the brain mask. Remove those points:
                % There shouldn't be any nans, but let's make sure:
                dt6Nans = any(isnan(dt6),2);
                if(any(dt6Nans))
                    dt6Nans = find(dt6Nans);
                    for(ii=1:6)
                        dt6(dt6Nans,ii) = 0;
                    end
                    summary(ii).fg(jj).errors = ['NOTE: ' length(dt6Nans) 'fiber points had NaNs. These will be ignored...'];
                else
                    summary(ii).fg(jj).errors = 'No NaN errors...';
                end
                [vec,val] = dtiEig(dt6);
                val = val./1000; % Our ADCs are in um^2/sec, but we like um^2/msec
                nonPD = find(any(val<0,2));
                if(~isempty(nonPD))
                    summary(ii).fg(jj).errors = [summary(ii).fg(jj).errors 'NOTE: ' length(nonPD) 'fiber points had negative eigenvalues. These will be clipped to 0...'];
                    val(val<0) = 0;
                end
                fa = dtiComputeFA(val);
                md = sum(val,2)./3;
                % fdImg = dtiComputeFiberDensityNoGUI(h.fiberGroups, xformImgToAcpc, imSize, fiberGroupNum, endptFlag, fgCountFlag);

                % Fill in SUMMARY fields
                summary(ii).fg(jj).length = mean(l)*stepSize; 
                summary(ii).fg(jj).numFibers = length(fg.fibers);
                summary(ii).fg(jj).meanFA = mean(fa);
                summary(ii).fg(jj).meanMD = mean(md);
                summary(ii).fg(jj).densityVol = 'Need to write code for this';
            end
        end
    end
end