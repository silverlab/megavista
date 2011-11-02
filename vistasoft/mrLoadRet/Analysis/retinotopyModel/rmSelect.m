function view = rmSelect(view, loadModel, rmFile)
% rmSelect - select retinotopy model file and put in view struct
%
% view = rmSelect([view=current view], [loadModel=0], [rmFile=dialog]);
%
% The loadModel flag indicates whether the model file (a large file)
% should be loaded or not. By default it is 0: don't load it until needed
% (only the path to the selected rmFile file will be stored). If it's 1, it
% goes ahead and loads it.
%
% If the path to the retinotopy model file is provided as a third argument,
% will attempt to load it directly; otherwise, pops up a dialog.  You
% may also provide the string 'mostrecent' as the filename, in which case
% the code will look for the most recently-created model file, and 
% select it (producing an error if one is not found).
%
% 2006/02 SOD: wrote it.
% ras 2006/10: added dialog.
% ras, 06/07: added 'mostrecent' flag to find the newest file
if ~exist('view','var') || isempty(view), view = getCurView;  end;
if ~exist('loadModel','var') || isempty(loadModel), loadModel = true;   end;

% choose filename:
if ~exist('rmFile','var') || isempty(rmFile),
    rmFile = getPathStrDialog(dataDir(view),...
        'Choose retinotopic model file name', ...
        '*.mat');
    drawnow;
elseif iscell(rmFile)
    rmFile = rmFile{1};
end

% if user just wants the newest file, check for it:
if ischar(rmFile) && ismember(lower(rmFile), {'newest' 'mostrecent'})
	pattern = fullfile( dataDir(view), 'retModel-*.mat' );
	w = dir(pattern);
	if isempty(w)
		error('Most Recent File selected; no retModel-* files found.')
	end
	[dates order] = sortrows( datevec({w.date}) ); % oldest -> newest
	rmFile = fullfile( dataDir(view), w(order(end)).name );
end

% if the load model flag is 1, but the file's already selected, just load
% it and return:
if loadModel && checkfields(view, 'rm' , 'retinotopyModelFile')
    if ~exist(rmFile, 'file')
        error('Model file %s not found.', rmFile);
    end;
    load(rmFile, 'model', 'params');
    view = viewSet(view, 'rmFile', rmFile);
    view = viewSet(view, 'rmModel', model);
    view = viewSet(view, 'rmParams', params);
    view = viewSet(view, 'rmModelNum', 1);
    return;
end;

if ~exist(rmFile,'file') 
    if exist([rmFile '.mat'], 'file')
        rmFile = [rmFile '.mat'];
    elseif check4File(fullfile(dataDir(view), rmFile))
        rmFile = fullfile(dataDir(view), rmFile);
    else
        disp(sprintf('[%s]:No file: %s',mfilename,rmFile));
        return;
    end
end
    
% store rmFile filename:
view = viewSet(view,'rmFile',rmFile);

if loadModel==0
    % clear previous models but don't load them untill we need them:
    view = viewSet(view, 'rmModel', []);
else
    % go ahead and load
    load(rmFile, 'model', 'params');
    view = viewSet(view, 'rmModel', model);
    view = viewSet(view, 'rmParams', params);
    view = viewSet(view, 'rmModelNum', 1);
end;
    

return;

