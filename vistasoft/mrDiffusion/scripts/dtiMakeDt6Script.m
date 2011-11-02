
% initialize t1 anatomies
baseDir = '/biac3/wandell4/data/reading_longitude/dti_y4';
s = dir(fullfile(baseDir,'*07*'));
s = s([s.isdir]); s = {s(:).name};
for(ii=1:length(s))
  disp(['Processing ' s{ii} '...']);
  bd = fullfile(baseDir,s{ii},'raw');
  outDir = fullfile(baseDir,s{ii},'t1');
  if(~exist(outDir,'dir')) mkdir(outDir); end
  d = dir(fullfile(bd,'spgr*'));
  d = d([d.isdir]); d = {d(:).name};
  for(jj=1:length(d)) 
    rawDir = fullfile(bd,d{jj});
    outFile = fullfile(outDir,sprintf('%s_t1anat%s',s{ii},d{jj}(5:end)));
    disp(['  ' rawDir '  ' outFile]);
    myGunzip(fullfile(rawDir,'*.gz'));
    [outFileName,imData] = mrAnatMakeNiftiFromIfiles(rawDir, outFile, 'silent');
    % create a montage of every 4th z slice
    sz = size(imData);
    if(sz(3)>(sz(1)+sz(2))/2)
      cropSl = round(sz(3)*.25);
      sl = [cropSl:4:sz(3)-cropSl];
    else
      sl = [1:4:sz(3)];
    end
    m = makeMontage(flipdim(permute(imData,[2 1 3]),1),sl);
    m = uint8(mrAnatHistogramClip(double(m),.3,.98)*255+.5);
    imwrite(m,gray(256),[outFile '_montage.png']);
    myGzip(fullfile(rawDir,'*'));
  end
end


% Create averaged t1, aligned to previous year's t1.
baseDir = '/biac3/wandell4/data/reading_longitude/dti_y4';
s = dir(fullfile(baseDir,'*07*'));
s = s([s.isdir]); s = {s(:).name};
[y0f,y0s] = findSubjects(fullfile('/biac2/wandell2/data/reading_longitude/dti_y2','*0*'),'*_dt6_noMask',{});
for(ii=1:length(s))
  disp(['Processing ' s{ii} '...']);
  bd = fullfile(baseDir,s{ii},'t1');
  d = dir(fullfile(bd,'*_t1anat*.nii.gz'));
  d = d(~[d.isdir]);
  % Remove any t1 file with 'avg' in it's name:
  d = d(cellfun('isempty',strfind({d.name},'avg')));
  clear srcFiles;
  if(isempty(d)) 
    disp(' No nifti files!');
  else
    for(jj=1:length(d)) srcFiles{jj} = fullfile(bd,d(jj).name); end;
    outFile = fullfile(bd,[s{ii} '_t1anat_avg.nii.gz']);
    z = strfind(s{ii},'0');
    y0Ind = strmatch(s{ii}(1:z(1)),y0s);
    dt6File = y0f{y0Ind};
    t1File = fullfile(fileparts(dt6File),'t1','t1.nii.gz');
    if(exist(t1File,'file'))
      fprintf('   Creating ...%s from ',outFile(end-40:end));
      for(jj=1:length(srcFiles)) fprintf(' ...%s',srcFiles{jj}(end-26:end)); end
      fprintf('\n');
      im = mrAnatAverageAcpcNifti(srcFiles, outFile, t1File, [], [], [], false);
      %ni = readFileNifti(outFile); im=ni.data;
      sz = size(im);
      cropSl = round(sz(3)*.25);
      sl = [cropSl:4:sz(3)-cropSl];
      m = makeMontage(flipdim(permute(im,[2 1 3]),1),sl);
      m = uint8(mrAnatHistogramClip(double(m),.3,.98)*255+.5);
      imwrite(m,gray(256),fullfile('/tmp/',[s{ii} '.png']));
    else
      disp(['   Skipping due to missing file: ' t1File '.']); 
    end
  end
end  
error('stop here');


baseDir = '/biac2/wandell2/data/reading_longitude/dti_y3';
%baseDir = '/biac2/wandell2/data/reading_longitude/dti_adults';
%[f,s] = findSubjects(fullfile(baseDir,'*0*'),'*_dt6',{});
s = dir(fullfile(baseDir,'*0*'));
s = s([s.isdir]);
s = {s(:).name};

dtiDir = 'dti_6dir_fatsat';
outNameSuffix = 'dt6_noMask';

for(ii=2:length(s))
  bd = fullfile(baseDir,s{ii});
  myGunzip(fullfile(bd,dtiDir,'*.gz'));
  b0 = fullfile(bd,dtiDir,'B0_001.dcm');
  if(~exist(b0,'file'))
    disp(['Can''t find a B0_001.dcm file- aborting on ' s{ii} '(#' num2str(ii) ')']);
    continue;
  end
  d = dir(fullfile(bd,'t1',[s{ii}(1:2) '*_t1anat_avg.nii.gz']));
  if(length(d)~=1)
    d = dir(fullfile(bd,'t1',[s{ii}(1:2) '*_t1anat.hdr']));
    if(length(d)~=1)
      d = dir(fullfile(bd,'t1',[s{ii}(1:2) '*_t1anat_avg.hdr']));
      if(length(d)~=1)
	disp(['Can''t find a *_t1anat- aborting on ' s{ii} '(#' num2str(ii) ')']);
	continue;
      end
    end
  end
  t1 = fullfile(bd,'t1',d.name);
  dt6 = fullfile(bd, [s{ii} '_' outNameSuffix]);
  %cmd = ['dtiMakeDt6(''' b0 ''',''' t1 ''',''' dt6 ''', 0, 0);'];
  dtiMakeDt6(b0, t1, dt6, 0, 0);
  myGzip(fullfile(bd,dtiDir,'*.*'));
end

error('Finished building dt6 files.');

  
% Fix brain masks
for(ii=1:length(s))
  disp(['processing ' s{ii} '...']);
  bd = fullfile(baseDir,s{ii});
  d = load(fullfile(bd, [s{ii} '_dt6']),'anat');
  dnew = load(fullfile(bd, [s{ii} '_dt6_noMask']),'anat');
  if(sum((d.anat.img(:)-dnew.anat.img(:)).^2)>100)
    warning('   RMS error too large- these are not the same data! Skipping.');
  else
    anat = dnew.anat;
    anat.brainMask = d.anat.brainMask;
    %anat.talScale = d.anat.talScale;
    save(fullfile(bd, [s{ii} '_dt6_noMask']),'anat', '-APPEND');
  end
end

error('stop here');

% Fix tal scales
baseDir = '/biac2/wandell2/data/reading_longitude/dti_y2';
[y1f,y1s] = findSubjects(fullfile('/biac2/wandell2/data/reading_longitude/dti','*0*'),'*_dt6',{});
%baseDir = '/biac2/wandell2/data/reading_longitude/dti_adults';
[f,s] = findSubjects(fullfile(baseDir,'*0*'),'*_dt6_noMask',{});
fh = figure;
for(ii=1:length(s))
  bd = fullfile(baseDir,s{ii});
  z = strfind(s{ii},'0');
  dt6old = load(y1f{strmatch(s{ii}(1:z(1)),y1s)},'anat');
  dt6new = load(f{ii},'anat');
  old = mrAnatHistogramClip(double(dt6old.anat.img),.4,.99);
  new = mrAnatHistogramClip(double(dt6new.anat.img),.4,.99);
  old = old-(mean(old(:))-mean(new(:)));
  rgb(:,:,:,1) = old;
  rgb(:,:,:,2) = old;
  rgb(:,:,:,3) = new;
  mrAnatMontage(rgb,dt6new.anat.xformToAcPc,[-40:4:76],fullfile(bd,[s{ii} '_t1_y1_vs_y2.png']),fh);
  rmsErr = sqrt(sum((old(:)-new(:)).^2));
  fprintf('%s: RMS = %0.2f\n',s{ii},rmsErr);
  anat = dt6new.anat;
  anat.talScale = dt6old.anat.talScale;
  save(fullfile(bd, [s{ii} '_dt6_noMask']),'anat', '-APPEND');
end

error('stop here');
