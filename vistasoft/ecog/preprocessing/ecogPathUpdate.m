function par = ecogPathUpdate(par)
% Update path info based on par.basepath
% This is a patch which enables better portability between computers.
% The folder paths are hardcoded. This function rewrites the paths
% so that they all match par.basepath. As long as you have set par.basepath
% to match your current machine, the rest will follow.
% jc 10/08/10

dir_names = {'RawData','ArtData','CARData','CompData',...
    'FiltData','RerefData','SpecData','Results','Print'};
% Directory contents:
% CARData: Common average referencing (CAR)
% CompData: Compiled data, all chans in one mat
% FiltData: Notch filtered data
% reRefData: Rereferenced data
% SpecData: Spectral data
for n = 1:length(dir_names)
    newblock = fullfile(par.basepath,dir_names{n},par.block);
    par.(dir_names{n}) = newblock;
end

par.BehavData = fullfile(par.basepath,'BehavData');