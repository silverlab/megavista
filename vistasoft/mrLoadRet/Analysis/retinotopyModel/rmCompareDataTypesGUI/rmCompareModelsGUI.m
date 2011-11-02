function h = rmCompareModelsGUI(view, roi, dtList, modelList);
% Open a GUI to compare the time series between different data types.
%
% h = rmCompareModelsGUI(view, [roi], [dtList=dialog], [modelList=dialog]);
%
% INPUTS:
%	view: mrVista view. [default: current view]. 
%
%	roi: ROI specification. Will compare data across models for this ROI.
%	[default: view's selected ROI]
%
%	dtList: list (cell array) of data type names. [default: put up a
%	dialog]
%
%	modelList: list of model files from each data type to compare. If -1,
%	will use the default model files found for each data type. [default:
%	put up a dialog].
%
%
% ras, 02/2009.
if notDefined('view'),	view = getCurView;		end
if notDefined('roi'),	roi = view.selectedROI;	end

if notDefined('dtList')
	% put up a dialog to get list
	dtList = rmSelectDataTypes(view);
end

if notDefined('modelList') 
	% put up a dialog to select models for each data type
	modelList = rmSelectModels(view, dtList, 0);
elseif isequal(modelList, -1)
	% special case: choose default RM models for each data type
	modelList = rmSelectModels(view, dtList, 1);	
end

%% create a structure with the multiple model params
M = rmCompareModelsGUI_getData(view, roi, dtList, modelList); 

%% open the GUI window
M = rmCompareModelsGUI_openFig(M);

%% do an initial refresh
rmCompareModelsGUI_update(M);

return
% /--------------------------------------------------------------/ %



% /--------------------------------------------------------------/ %
function dtList = rmSelectDataTypes(view);
%% dialog to select one ore more data types to compare.
mrGlobals;
allDtNames = {dataTYPES.name};
reply = buttondlg('Select Data Types to Compare', allDtNames);
if isempty(reply), error('User Aborted.');		end
dtList = allDtNames(reply==1);
return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function modelList = rmSelectModels(view, dtList, defaultFlag);
%% dialog to select a pRF model for each data type in dtList.
% first, scan each data type to come up with a good default model.
for ii = 1:length(dtList)
	modelList{ii} = rmDefaultModelFile(view, dtList{ii});
end

% special case: use the defaults without putting up a dialog?
if defaultFlag==1,	return;		end

% now, build a dialog with file paths for each model
for ii = 1:length(dtList)
	dlg(ii).fieldName = ['modelFile' num2str(ii)];
	dlg(ii).style = 'filename';
	dlg(ii).string = [dtList{ii} ' Model File'];
	dlg(ii).value = modelList{ii};
end

% put up the dialog, get user response
ttl = 'Select Retinotopy Model Files to Compare';
[resp ok] = generalDialog(dlg, ttl, 'center');
if ~ok
	error('User Aborted.')
end

% parse the response
for ii = 1:length(dtList)
	modelList{ii} = resp.(['modelFile' num2str(ii)]);
end

return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %


	