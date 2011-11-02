% function fg = dtiCreateStats(fg, aggregate_name, local_name, is_computed_per_point, img, type)
% 
% Add a geometry or image stat to a fiber group. 
% Returns the new fiber group
% 
% Example
% Geometric Stat
% fg = dtiCreateStat(fg,'Length','Length', 1);
%
% Image Stat
% fg = dtiCreateStat(fg,'FA_avg','FA', 1, fa_img, 'avg');
%
% dtiCreateStats takes the following inputs
%
% fg                    : Fiber Group
% aggregate_name        : Name of the aggregate statistic
% local_name            : Name for the local or per point statistic
% is_computed_per_point : 1 if computed per point, 0 if not
% 
% Stats below are needed for image based stats only
% 
% img : A nifti Image file. If the nifti image file is not supplied the stat
%       assumed to be a geometry stats. In this case, a stat is only 
%       generated if the name is length
% type: Type of the stat can be 'avg', 'min', 'max'. This field is 
% considered only if a nifti image file is supplied. In case of a geometry 
% stat(no nifti image given) this stat is ignored.
% 
% HISTORY:
% 2009.06.17 : SA wrote it
function fg=dtiCreateStats(fg, aggregate_name, local_name, is_computed_per_point, img, type)

% Check if input params are ok
if nargin < 4 
    disp ('Require at least 4 params');
    return;
end

if ~isstruct(fg) || ~isfield(fg,'pathwayInfo')
    disp('fg should be a proper fibergroup struct');
    return;
end


if ~isfield(fg,'params') || isempty(fg.params)
    idx = 1;
else
    idx = length(fg.params)+1;
end

param = struct;
param.name = aggregate_name;
param.uid = idx-1;
param.ile=1; param.icpp=is_computed_per_point; param.ivs=1;
param.agg = aggregate_name;
param.lname=local_name;
param.stat = [];
% Geometry case
if nargin == 4
    if strcmpi(aggregate_name,'length') ~= 1
        disp('Only length statistic is support for geometric stats');
        return;
    end

    
    for ff=1:length(fg.fibers)
        fiber = fg.fibers{ff};
        if(size(fiber,2)<size(fiber,1)); fiber=fiber'; end
        mmPerStep = sqrt(sum((fiber(:,1)-fiber(:,2)).^2));
        param.stat(ff) = mmPerStep*(size(fiber,2)-1);
        fg.pathwayInfo(ff).pathStat(idx)=param.stat(ff);
        fg.pathwayInfo(ff).point_stat_array(idx,:)=mmPerStep*[0:1:size(fiber,2)-1];
    end
    
else % image statistic
    if strcmpi(type,'avg') ~= 1 && strcmpi(type,'min') ~= 1 && strcmpi(type,'max') ~= 1
        disp('The type of stat for image statistic should be either of min, max or avg');
        return;
    end

    if ~isfield(img,'qto_ijk') || ~isfield(img,'data')
        disp('img should be a proper nifti image structure');
        return;
    end
        
    for ff=1:length(fg.fibers)
        fiber = fg.fibers{ff};
        if(size(fiber,2)<size(fiber,1)); fiber=fiber'; end
        imgCoords = round(mrAnatXformCoords(img.qto_ijk, fiber));
        for i = 1:length(imgCoords)
            fg.pathwayInfo(ff).point_stat_array(idx,i)=img.data(imgCoords(i,1), imgCoords(i,2), imgCoords(i,3));
        end
        
        switch(lower(type))
            case 'avg'
                param.stat(ff) = sum(fg.pathwayInfo(ff).point_stat_array(idx,:)) / length(fiber);                
            case 'min'
                param.stat(ff) = min(fg.pathwayInfo(ff).point_stat_array(idx,:));                
            case 'max'
                param.stat(ff) = max(fg.pathwayInfo(ff).point_stat_array(idx,:));                
        end
        fg.pathwayInfo(ff).pathStat(idx)=param.stat(ff);
    end
end

fg.params{idx} = param;
end