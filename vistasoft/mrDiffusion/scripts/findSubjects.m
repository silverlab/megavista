function [subList,subCodes,subDirs,subLetters] = findSubjects(baseDir, dtDir, excludeList)
%
% [subList,subCodes,subDirs,subLetters] = findSubjects([baseDir], [dtDir='dti06'], [excludeList={}])
%
% Function to find all the files in baseDir that match "*fileNameFragment*.ext".
% 
% Returns cell array with filenames and the 'subCodes'- basically the first
% few characters of the filename (path removed).
% Anything that matches the exclude list is, well, excluded.

if(~exist('baseDir','var') || isempty(baseDir))
    if(ispc)
        baseDir = '//171.64.204.10/biac2-wandell2/data/reading_longitude/dti/*0*';
    else
        baseDir = '/biac3/wandell4/data/reading_longitude/dti_y1/*0*';
    end
end
if(~iscell(baseDir) && baseDir(end)=='*')
  tmp = dir(baseDir);
  oldBd = fileparts(baseDir);
  clear baseDir;
  jj = 0;
  if(isempty(tmp)) error('No files found!'); end
  for(ii=1:length(tmp))
    if(tmp(ii).isdir)
      jj = jj+1;
      baseDir{jj} = fullfile(oldBd, tmp(ii).name);
    end
  end
  if(jj==0) baseDir = oldBd; end
end
if(~iscell(baseDir))
  baseDir = {baseDir};
end
if(~exist('dtDir','var') || isempty(dtDir))
  dtDir = 'dti06';
end
defaultExcludeList = {'dh040607','es041113','mb040927','pt041013','tk040817','mb041004','nad040610','vt040717','zs040630'};
if(~exist('excludeList'))
    excludeList = {};
elseif(~isempty(excludeList) && strcmp(excludeList{1}, '...'))
    excludeList = [defaultExcludeList, excludeList];
end

% dh040607: DTI data look noisy and have substantial atifacts. They might
% not be a total loss- the right occipital lobe is espicially bad, but
% other areas are OK.
% es041113: very bad T1-DTI registration- but it probably can be fixed.
% mb040927: T1's look OK, but DTI are junk. Looks like we didn't get enough
% repeats. MB also has unusual-looking ventricles. NOTE: we have good data
% on MB from another session- see mb041004.
% pt041013: very bad T1-DTI registration (similar to es). Can be fixed.
% tk040817: T1's OK, but DTI s have very large distortions, esp. in frontal
% lobes. Perhaps due to dentalwork?

subList{1} = '';
subCodes{1} = '';
subDirs{1} = '';
subLetters{1} = '';

nFiles = 1;
for(jj=1:length(baseDir))
    fn = fullfile(baseDir{jj}, dtDir, 'dt6.mat');
    if(exist(fileparts(fn),'dir') && exist(fn,'file'))
        [junk,subDir] = fileparts(fileparts(fileparts(fn)));
        if(~isempty(strmatch(subDir, excludeList)))
            disp([fn ' is in the exclude list- skipping.']);
        else
            subCodes{nFiles} = subDir;
            us = findstr(subDir, '0');
            if(~isempty(us) && us(1)<numel(subDir))
                subLetters{nFiles} = subDir(1:us(1)-1);
            else
                subLetters{nFiles} = '';
            end
            subList{nFiles} = fn;
            subDirs{nFiles} = baseDir{jj};
            nFiles = nFiles+1;
        end
    end
end
return
