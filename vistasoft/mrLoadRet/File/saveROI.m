function [view, status, forceSave] = saveROI(view, ROI, local, forceSave)
%
% [view, status, forceSave] = saveROI([view=cur view], [ROI='selected'], [local], [forceSave=0])
%
% Saves ROI to a file.
%
% INPUTS:
% view: mrVista view. Finds current view if omitted.
%
% ROI: ROI structure, or index into ROI structure. Entering 'selected' 
% as ROI will cause the view's selected ROI to be saved. [This is the 
% default behavior if the ROI argument is omitted.]
%
% local: flag to save ROI in a local directory to the view (e.g.,
% 'Volume/ROIs'), or a shared directory (e.g., relative to the
% anatomy directory -- use "setpref('VISTA', 'defaultROIPath')" to 
% set this directory.)  [For inplanes, defaults to 1, save locally. 
% for other views, defaults to 0, saves in shared directory.]
%
% forceSave: if set to 0, if the ROI file exists, will ask the user if they
% want to save over the existing file. If 1, will save over existing files
% without asking. Useful for scripting. [Defaults to 0].
%
% OUTPUTS:
%   view: modified view.
%   status: 0 if the ROI saving was aborted. This is used when calling this
%           repeatedly (see 'saveAllROIs'), if the file exists and the
%           user selects 'Cancel'.
%   forceSave: modified forceSave flag, if the file exists, and the user
%           wants to bypass the dialog for future files. (again, see 
%           'saveAllROIs'.)
%
% djh, 1/24/98
% gmb, 4/25/98 added dialog box
% ARW 10/06/05 : Added default ROI path option
% (see also roiDir)
% ras 07/06: added forceSave flag.
% ras 10/06: ROI selection defaults to 'selected'; can enter ROI indices.
% ras 11/06: offers option to save over all, returning modified forceSave
% flag. (Very helpful when saving a lot of ROIs that you want to update.)

if notDefined('view'),      view = getCurView;      end
if notDefined('forceSave'), forceSave = 0;          end
if notDefined('ROI'),       ROI = 'selected';       end
if notDefined('local'),    
    local = isequal(view.viewType, 'Inplane');         
end

status = 0;
verbose = prefsVerboseCheck;

% disambiguate the ROI specification
if isnumeric(ROI), ROI = tc_roiStruct(view, ROI); end

if ischar(ROI) && isequal(lower(ROI), 'selected')
    ROI = view.ROIs( view.selectedROI );
end

if isfield(ROI, 'roiVertInds')
    ROI = rmfield(ROI,'roiVertInds');
end 

if isempty(ROI.coords) && forceSave==0
    q = sprintf('Save empty ROI %s?', ROI.name);
    confirm = questdlg(q, mfilename, 'Yes', 'No', 'No');
    if ~isequal(confirm, 'Yes'), disp('ROI not saved.'); return; end
end

% The method of saving the ROI starts here
% First we make sure we add a .mat extension. Matlab does this most of
% the times but not always, for example if your name contains a '.'.
% It still saves the file but without '.mat' and consequently cannot load it.
[p,n,ext]=fileparts(ROI.name);
if ~strcmp(ext,'.mat')
  ROIname = [ROI.name '.mat'];
else,
  ROIname = ROI.name;
end;
pathStr = fullfile(roiDir(view,local), ROIname);

if check4File(pathStr) && forceSave==0
    q = sprintf('ROI %s already exists.  Overwrite?', ROI.name);
    saveFlag = questdlg(q, 'Save ROI', 'Yes', 'No', 'Yes To All', 'No');
else
    saveFlag = 'Yes';
end

switch saveFlag
    case 'Yes'
        fprintf('Saving ROI "%s" in %s. \n', ROI.name, fileparts(pathStr));        
        save(pathStr,'ROI');
        status = 1;
        
    case 'No'
        if verbose,  fprintf('ROI %s not saved.', ROI.name);    end
        status = 1;     % not saved, but keep going if saving many ROIs
        
    case 'Yes To All'
        if verbose,     disp('Force-Saving all ROIs...');       end
        fprintf('Saving ROI "%s" in %s. \n', ROI.name, fileparts(pathStr));        
        forceSave = 1;
        status = 1;
        
    case 'Cancel'
        if verbose,  disp('ROI Saving Aborted.');               end
end

return;
