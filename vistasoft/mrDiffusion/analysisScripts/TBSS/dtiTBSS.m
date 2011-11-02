
if(ispc)
    baseDir = '//171.64.204.10/biac2-wandell2/data/reading_longitude';
else
    baseDir = '/biac2/wandell2/data/reading_longitude';
end

outDir = '/teal/scr1/dti/tbss';

%subDir = fullfile(baseDir,'dti_adults','*0*');
    
outDir = fullfile(outDir, 'child_y1');
mkdir(outDir);
subDir = fullfile(baseDir,'dti','*0*');
skipSubs = {};
[f,sc] = findSubjects(subDir,'*_dt6_noMask',skipSubs);

N = length(f);

for(ii=1:N)
  disp(['Processing ' sc{ii} '...']);
  baseFname = fullfile(outDir, [sc{ii} '_']);
  dt = load(f{ii},'dt6','xformToAcPc','dtBrainMask');
  dt.dt6(~repmat(dt.dtBrainMask,[1 1 1 6])) = 0;
  [eigvec,eigval] = dtiEig(dt.dt6);
  fa = single(dtiComputeFA(eigval));
  fa(isnan(fa)) = 0;
  % ./1000 to convert to micrometers^2/msec
  axialAdc = single(eigval(:,:,:,1)./1000);
  radialAdc = single((eigval(:,:,:,2)+eigval(:,:,:,3))./2./1000);
  dtiWriteNiftiWrapper(fa, dt.xformToAcPc, [baseFname 'fa'], 1, ['extracted from ' f{ii}]);
  dtiWriteNiftiWrapper(axialAdc, dt.xformToAcPc, [baseFname 'axialADC'], 1, ['extracted from ' f{ii}]);
  dtiWriteNiftiWrapper(radialAdc, dt.xformToAcPc, [baseFname 'radialADC'], 1, ['extracted from ' f{ii}]);
end


% tbss_1_preproc
% tbss_2_reg



  
