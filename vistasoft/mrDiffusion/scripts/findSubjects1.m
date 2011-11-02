function [subList,subCodes] = findSubjects1(baseDir, fileNameFragment, excludeList)
%
% [subList,subCodes] = findSubjects(baseDir, fileNameFragment, excludeList)
%
% Function to find dt6 files for all subjects - returns cell array with
% filenames of form "subCode_dt6_acpc_2x2x2mm.mat"

if(~exist('baseDir','var') | isempty(baseDir))
  baseDir = '//snarp/u1/data/reading_longitude/dti/*0*';
end
if(~iscell(baseDir) & baseDir(end)=='*')
  tmp = dir(baseDir);
  clear baseDir;
  jj = 1;
  for(ii=1:length(tmp))
    if(tmp(ii).isdir)
      baseDir{jj} = fullfile('//snarp/u1/data/reading_longitude/dti/', tmp(ii).name);
      jj = jj+1;
    end
  end
end
if(~iscell(baseDir))
  baseDir = {baseDir};
end
if(~exist('fileNameFragment','var') | isempty(fileNameFragment))
  fileNameFragment = '_dt6';
end

%if you want to not exclude anything =>don't pass an exclude list.
%if you want to exclude the default list => pass 'default' as the exclude list
%if you want to exclude a certain list plus the default => pass in '...' as
%the first item of excludeList

defaultExcludeList = {'dh040607','es041113','mb040927','pt041013','tk040817','mb041004','nad040610','vt040717','zs040630'};

if(~exist('excludeList','var') | isempty(excludeList))
    excludeList = {};
elseif(~isempty(excludeList) & strcmp(excludeList{1}, '...'))
    excludeList = [defaultExcludeList, excludeList];
end
if((~isempty(excludeList)) & strcmp(excludeList{1},'default'))
    excludeList = defaultExcludeList;
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
nFiles = 1;
for(jj=1:length(baseDir))
    tmp = dir(fullfile(baseDir{jj}, ['*' fileNameFragment '*.mat']));
    for(ii=1:length(tmp))
        fn = fullfile(baseDir{jj}, tmp(ii).name);
        us = findstr(tmp(ii).name, '_');
        subCodes{nFiles} = tmp(ii).name(1:us(1)-1);
        if(~exist(fn, 'file'))
            disp([fn ' not found- skipping.']);
        elseif(~isempty(strmatch(subCodes{nFiles}, excludeList)))
            disp([tmp(ii).name ' is in the exclude list- skipping.']);
        else
            subList{nFiles} = fn;
            nFiles = nFiles+1;
        end
    end
end
return
