function vw = smInitView(vw, roiX, roiY, addArg)
%
% This function is not used for anything. Do we want it?
%
%
% smInitView - initiate view struct from key pointers
% 
% view = vw = rmInitView(vw, roiX, roiY, addArg)
%
%

% JW: wrote it.

mrGlobals;

%--------------------------------------------------------------------------
% Check Args
if notDefined('vw'), error('Need view'); end;
if notDefined('roiX'), error('Need roiX'); end;
if notDefined('roiY'), error('Need roiY'); end;
%--------------------------------------------------------------------------

% default vista stuff
if ~isstruct(vw),
  loadSession;
  vw=initHiddenGray;
end; 


% set dataType
vw = viewSet(view,'curdatatype',viewPointer(2));
disp(sprintf('[%s]:DataType: %s',mfilename, ...
             dataTYPES(vw.curDataType).name));

% if roiFileName load roi
if ~isempty(roiFileName) 
  if ~strcmp(roiFileName,'0')
    vw = loadROI(vw,roiFileName,[],[],[],1);
  end;
end;


return;

