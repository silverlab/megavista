function stats = ctrCompStatsORBundles(wDir,statsFile,subjDirs,pathFiles,eigSampling)
%Compute eigenvalue statistics on an OR bundle from contrack
%
%   stats = ctrCompStatsORBundles(wDir,statsFile,subjDirs,pathFiles)
%
% The idea here is that we have a segmented Optic Radiation inside of the
% subject's fibers/conTrack/or_clean directory.  This program reads the OR
% data and analyzes the eigenvalues of the voxels along the path.
%
% The program is set up assuming that there might be many subject
% directories inside of the current working directory.
%
% The working directory for the dti data is wDir.  
% The subject directories are inside of wDir
% The file names are the cleaned fiber files
% statsFile is the output file. 
%
% Other input parameters will be specified.
% This code was used for the JOV OR paper by Sherbondy et al.
% It may not be general.
%
% BW should describe issues about eigenvalue sampling here --
%
% Examples:
% 
%   subjDirs = {'aab050307', 'ah051003', 'as050307', 'db061209', 'dla050311','gm050308', 'jy060309', 'me050126'};
%   pathFiles = {'LOR_meyer_final.pdb','LOR_central_final.pdb','LOR_direct_final.pdb'};
%   pathFiles(2,:) = {'ROR_meyer_final.pdb','ROR_central_final.pdb','ROR_direct_final.pdb'};
%   wDir = pwd; statsFile = 'controlORStats.mat';
%   stats = ctrCompStatsORBundles(wDir,statsFile,subjDirs,pathFiles)
%
%   clear subjDirs; subjDirs{1} = 'forTony'; wDir = pwd;
%   clear pathFiles;
%   pathFiles(1,1) = {'pathsL_0.5_contrack_clean.mat'}; 
%   pathFiles(2,1) = {'pathsR_0.9_contrack_clean.mat'};
%   statsFile = 'mmORStats.mat';
%   stats = ctrCompStatsORBundles(wDir,statsFile,subjDirs,pathFiles) 
%
%  clear subjDirs; subjDirs{1} = 
%

% The defaults are for the original Sherbondy examples.  Some day they
% should go away - or perhaps this function will go away.
if notDefined('wDir'), wDir = pwd; end
if notDefined('statsFile'), statsFile = 'evStats.mat'; end
if notDefined('subjDirs'), 
     subjDirs = {'aab050307', 'ah051003', 'as050307', 'db061209', 'dla050311','gm050308', 'jy060309', 'me050126'};
end
if notDefined('pathFiles')
    pathFiles = {'LOR_meyer_final.pdb','LOR_central_final.pdb','LOR_direct_final.pdb'};
    pathFiles(2,:) ={'ROR_meyer_final.pdb','ROR_central_final.pdb','ROR_direct_final.pdb'};
end
if notDefined('eigSampling'), eigSampling = 'uniqueeig'; end

% Directory with the OR fibers cleaned up
fName = 'or_clean';

% We should check to see whether statsFile is sent in.  If not, we use
% mrVSelectFile to choose the output file name.

% For each subject
for ss = 1:length(subjDirs)
    curDir = fullfile(wDir,subjDirs{ss});
    fiberDir = fullfile(curDir,'fibers','conTrack',fName);
    dt = dtiLoadDt6(fullfile(curDir,'dti06','dt6.mat'));
    % For each hemisphere
    for hh=1:2
        % For each of the named files
        for pp=1:size(pathFiles,2)
            fprintf('\n Computing %s - %s ...', subjDirs{ss}, pathFiles{hh,pp});
            pathFile = fullfile(fiberDir,pathFiles{hh,pp});

            [p,n,e] = fileparts(pathFile);
            
            % Read the fiber group, no geometric transformation
            switch e
                case '.pdb'
                    fg = mtrImportFibers(pathFile,eye(4));
                case '.mat'
                    % Read the fiber group as a Matfile
                    fg = dtiReadFibers(pathFile);
                otherwise
                    error('Unknown fiber file type');
            end
            
            fprintf('%d fibers',size(fg.fibers));
            % Get the eigenvalues for the fibers
            switch lower(eigSampling)
                case 'uniqueeig'
                    % We aren't sure if we should only get the unique eigenvalues
                    % or we should simply get the eigenvalues from every node.
                    eigVal = dtiGetUniqueEigValsFromFibers(dt, fg);
                case 'alleig'
                    % This is the one where we get all of the nodes, even if they
                    % are dupliate voxels
                    eigVal = dtiGetAllEigValsFromFibers(dt,fg);
                otherwise
                    error('Unknown sampling of fibers');
            end

            % Store them in the return variable
            stats{ss,hh,pp} = eigVal; %#ok<AGROW,NASGU>
        end
    end
end

save(statsFile,'subjDirs','pathFiles','stats');

return;
