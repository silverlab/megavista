%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%    gb 05/15/05
%
% This script has to be executed directly in the command line
% It loads the mean maps of the current dataType of the current view
% into the variable meanMap.
%
% The current inplane should be in the variable vw (default, but can be
% modified directly in the code)
%
% example :
%
%   close all
%   clear all
%   mrVista
%   vw = getSelectedInplane;
%   loadMeanMaps
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if ieNotDefined('vw')
    curName = 'Original';
else
    curType = viewGet(vw,'currentdataType');
    curName = dataTYPES(curType).name;
end

curDir = fullfile('Inplane',curName);

meanMap = load(fullfile(curDir,'meanMap.mat'));
meanMap = meanMap.map;

fprintf('MeanMap loaded from dataType %s',curName); 