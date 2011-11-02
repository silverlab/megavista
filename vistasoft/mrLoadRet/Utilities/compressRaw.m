function compressRaw(thedir, follow, overwrite)
% compress pfiles in a directory
%  compressRaw([thedir], [follow], [overwrite])
%
% thedir:    directory to copmpress pfiles
% follow:    boolean. if true, also search symbolic links within thedir for 
%            pfiles to compress [default = false]
% overwrite: boolean. if true, overwrite duplicate files without asking
%            user for confirmation (by using '-f' in linux command)
%            [default = false]
% Example 1: 
%   % Compress pFiles in the cur dir. Do not search through symbolic
%   % links.
%   compressRaw
% 
% Example 2
%   % Compress pfiles in the dir
%   % '/biac3/wandell4/data/hV4/VistaSessions/Retinotopy-3deg'. 
%   % Include pfiles found through symbolic links.
%   thedir = '/biac3/wandell4/data/hV4/VistaSessions/Retinotopy-3deg';
%   follow = true;
%   compressRaw(thedir, follow)
%
% Example 3
%   % Compress pfiles in several dirs
%   thedir{1} = '/biac2/wandell2/data';
%   thedir{2} = '/biac2/wandell6/data';
%   thedir{3} = '/biac3/wandell4/data';
%   thedir{4} = '/biac3/wandell5/data';
%   thedir{5} = '/biac3/wandell7/data';
%   compressRaw(thedir)
%
% 8/2009: written by JW. Linux command suggested by RFD.

curdir = pwd;
if notDefined('thedir'),    thedir    = curdir; end
if notDefined('follow'),    follow    = false;  end
if notDefined('overwrite'), overwrite = false;  end

if ~iscell(thedir), dirs{1} = thedir; else dirs = thedir; end

for ii = 1:length(dirs)
    
    if ~exist(dirs{ii}, 'dir'),
        warning('The directory %s doesn''t exist', mfilename, dirs{ii});  %#ok<WNTAG>
        continue
    else
        cd(dirs{ii});
    end
    
    if follow,    findarg = '-follow -name'; else findarg = '-name'; end
    if overwrite, ziparg = '-vf';            else ziparg =  '-v';    end
    msg = sprintf('!find . -type f %s ''P*.7'' ''P*.7.mag'' -not -name ''*.*.*z*'' -size +1024 -exec gzip %s {} \\;', findarg, ziparg);
    eval(msg);
    fprintf('[%s]: Pfiles in the directory %s have been compressed.\n', mfilename, dirs{ii});
    
end
cd(curdir)

return

