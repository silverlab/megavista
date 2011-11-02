% for each subject in the BA44-45 group, go over all full fgs and save
% meanFA (not done for now), nFibers, length per fg, in the sub fiber/44-45 dir.

% baseDir = '//white/snarp/u1/data/reading_longitude/dti_adults';%on teal
baseDir = 'R:\data\reading_longitude\dti_adults';% on cyan
f = {'ab050307','as050307','aw040809','bw040806','da050311','gm050308',...
        'jl040902','ka040923','mbs040503','me050126','mz040828',...
        'pp050208','rd040630','sn040831','sp050303'};% 15 subjects 6 directions only 

for(jj=1:length(f))
    cd(fullfile(baseDir, f{jj}, 'fibers\BA44-45'));
    d = dir('*_full*');
    fgNames = {d.name};
    %for each fg get number of fibers and mean length, min max and std
    %length
    keep=0;
    for(ii = 1:length(fgNames))
         if length(fgNames{ii})<43   % do not do the 'MNI' ones
            keep=keep+1;
            fgNamesKeep{keep} = fgNames{ii};
            fg = dtiReadFibers(fgNames{ii});
            nFibers(keep) = length(fg.fibers);
            l = cellfun('length',fg.fibers);
            maxLength(keep) = max(l);
            meanLength(keep) = mean(l);
            medianLength(keep) = median(l);
            stdLength(keep) = std(l);
        end    
    end        
    save(f{jj},'fgNamesKeep','nFibers', 'maxLength', 'meanLength', 'medianLength', 'stdLength');
    clear fgNames fg;

end


% similar stats collection for ROIs

baseDir = 'R:\data\reading_longitude\dti_adults';% on cyan
f = {'ab050307','as050307','aw040809','bw040806','da050311','gm050308',...
        'jl040902','ka040923','mbs040503','me050126','mz040828',...
        'pp050208','rd040630','sn040831','sp050303'};% 15 subjects 6 directions only 

for(jj=1:length(f))
    cd(fullfile(baseDir, f{jj}, 'ROIs\BA44-45'));
    d = dir('*_full*');
    ROInames = {d.name};
    %for each ROI get volume, center mass Tal coords
    for(ii = 1:length(ROInames))
        curRoiName = ROInames{ii};
        roi = dtiReadRoi(curRoiName);
        fullRoiNames{ii} = roi.name;
        ROIvolume(ii) = size(roi.coords,1);
        ROImeanTalCoords(ii,:) = mean(roi.coords);
    end        
    dataFileName = fullfile(baseDir, f{1},'ROIs\BA44-45\BA44-45GroupROIs',[f{jj} '_ROIstats']);
    save(dataFileName,'fullRoiNames','ROIvolume', 'ROImeanTalCoords');
    clear ROInames roi;
end
