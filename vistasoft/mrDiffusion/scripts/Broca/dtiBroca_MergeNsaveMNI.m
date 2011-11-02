% go to every subject in the BA44-45 list
% load all fiber groups that start with LBA44 (then LBA45, RBA44, RBA45) in the BA44-45\dissections dir
% merge them to LBA44_cleaned
% save

baseDir = 'U:\data\reading_longitude\dti_adults\';
subDirs = {'ab050307','as050307','aw040809','bw040806','da050311','gm050308',...
        'jl040902','ka040923','mbs040503', 'me050126', 'mz040828',...
        'pp050208', 'rd040630','sn040831','sp050303'};
fiberDir = 'fibers\BA44-45\dissections\';

fGroups = {'LBA44','LBA45','RBA44','RBA45'};
        
for ii = 1:length(subDirs)
    workDir = fullfile(baseDir,subDirs{ii},fiberDir);
    cd(workDir);
    
    % for each ROI, read all fg and merge them
    for jj = 1:length(fGroups)
        tmp = [fGroups{jj} '*fixed.mat'];
        d = dir(tmp);
        fileNames = {d.name};
        % load the first one, then loop on the rest and merge
        load(fileNames{1});
        mergedName = [fGroups{jj} '_cleaned'];
        mergedFG = dtiNewFiberGroup(mergedName,[],[],[],fg.fibers);
        for kk = 1:length(fileNames)
            fg1 = mergedFG;
            load(fileNames{kk});
            fg2 = fg;
            mergedFG = dtiMergeFiberGroups(fg1,fg2,mergedName);
        end
        newFileName = [mergedName '.mat'];
        fg = mergedFG;
        save(newFileName,'fg','versionNum','coordinateSpace');
        clear fg versionNum coordinateSpace mergedFG
    end
end
