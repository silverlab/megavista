baseDir = '/biac2/wandell2/data/reading_longitude/dti/*0*';
[files,subCodes] = findSubjects(baseDir, '_dt6', {'es041113','tk040817'});
N = length(files);

for(ii=[1:N])
  fiberDir = fullfile(fileparts(files{ii}),'fibers');
  load(fullfile(fiberDir,'LOcc_adjusted'));
  fc(ii,1) = length(fg.fibers);
  load(fullfile(fiberDir,'ROcc_adjusted'));
  fc(ii,2) = length(fg.fibers);
  load(fullfile(fiberDir,'LOcc_adjusted+CC_FA'));
  fc(ii,3) = length(fg.fibers);  
  load(fullfile(fiberDir,'ROcc_adjusted+CC_FA'));
  fc(ii,4) = length(fg.fibers);  
end
