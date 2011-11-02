% dti_FINRA_createMoriFiberGroups.m

% This script will loop through a group of subjects and track fibers using
% the tools in mrVista. It will also then save out each of the subgroups as
% a .pdb fiber group for use with Quench. It will also

% HISTORY: 
% 07/14/2011 - LMP Wrote it.

% Notes: 
% This script is set up be run on VTA in the SPAN lab. 

% startupFile = '/home/span/matlabfiles/startup.m';
% run(startupFile);
% cd('/biac2b/data1/finra');

%% I. Directory and Subject Informatmation
dirs          = 'dti40';  
logDir        = '/biac2b/data1/finra/DTI/';
baseDir       = {'/biac2b/data1/finra/', '/biac2b/data1/finra/session2'};
subsSession1  = {'ap','as','ba','bh','bp','cc','ch','cl','cn','ko','lb',...
                 'lg','ls','lu','me','mw','nh','nm','rc','sc','sw','sy',...
                 'te','th','ww'};
subsSession2  = {'bg','jo','kc','mc','md','na'};

for i = 1:numel(baseDir)
    if i == 1; subs = subsSession1;
    elseif i == 2; subs = subsSession2;
    end
    
    % Run the functions
    for ii=1:numel(subs)
        sub = dir(fullfile(baseDir{i},[subs{ii} '*']));
        if ~isempty(sub)
            subDir   = fullfile(baseDir{i},sub.name);
            dt6Dir   = fullfile(subDir,'DTI',dirs);
            fiberDir = fullfile(dt6Dir,'fibers','MoriGroups');
            
            if ~exist('fiberDir','file'); mkdir(fiberDir); end
            
            fprintf('\nProcessing %s\n', subDir);
            
            % Find mori groups
            dt6File = fullfile(dt6Dir,'dt6.mat');
            outFile = fullfile(fiberDir, 'MoriGroups.mat');
            dtiFindMoriTracts(dt6File,outFile,[],[],[],[],true);
            
            % Create invididual conTrack groups from the MoriGroups.mat
            cd(fiberDir)
            fg = dtiLoadFiberGroup('MoriGroups.mat');
            
            fprintf('Saving individual fiber groups... \n');
            for ff=1:20
                inds = find(fg.subgroup==ff);
                keep = fg.fibers(inds);
                name = fg.subgroupNames(ff).subgroupName;
                name(name==' ') = '';
                fgNames{ff} = [name '.pdb'];
                nfg = dtiNewFiberGroup(name,[],[],[],keep);
                mtrExportFibers(nfg,[name '.pdb']);
            end
            clear fg nfg
            
            % Attach FA Quench stats to each fiber group
            fprintf('Attaching FA statistic to fiber groups... \n');
            dtiCreateMap(dt6File,'fa','faMap.nii.gz');
            faMap = readFileNifti('faMap.nii.gz');
            for jj=1:length(fgNames);
                fg = mtrImportFibers(fgNames{jj});
                fg = dtiCreateQuenchStats(fg,'FA_avg','FA', 1, faMap, 'avg');
                mtrExportFibers(fg,fgNames{jj});
                clear fg
            end           
            
        else
            fprintf('% Does not exist, skipping...',subs{ii});
        end
    end
end
fprintf('\n Success. Done.\n');