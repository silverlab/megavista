function fg = fgSet(fg,param,val,varargin)
%Set data in a fiber group
%
%  fgSet(fg,param,val,varargin)
%
% Parameter list
%
%
%
% See also
%
%
% (c) Stanford VISTA Team

switch param
    case 'name'
        fg.name = val;
    case 'type'
        fg.type = val;
    case {'colorrgb','color'}
        fg.colorRgb = val;
    case 'thickness'
        fg.thickness = val;
    case 'visible'
        fg.visible = val;
        
        % Fibers
    case 'fibers'
        % The fibers are set as 
        fg.fibers = val; 
    case {'fibercoordinatespace','fcspace'}
        fg.fcSpace = val;
    case 'fibernames'
        fg.fiberNames = val;
    case 'fiberindex'
        fg.fiberIndex = val;
    case 'tensors'
        fg.tensors  = val;

    otherwise
        error('Unknown fg parameter %s\n',param);
end

return
