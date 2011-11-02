
baseDir = '/biac3/wandell4/data/reading_longitude';

excludeSubs = {'bw040922' 'ada041018' 'ajs040629' 'an041018' 'at040918' ...
 'ctr040618' 'dh040607' 'js040726' 'ks040720' 'lg041019' 'nad040610' 'tk040817'}; 

adultDir = fullfile(baseDir,'dti_adults','*0*');
childDir = fullfile(baseDir,'dti_y1','*0*');

[aFile,aSc,aDir,aSl] = findSubjects(adultDir);
[cFile,cSc,cDir,cSl] = findSubjects(childDir);

allFile = [aFile cFile];
allDir = [aDir cDir];
allSc = [aSc cSc];
adult = zeros(1,length(allSc));
adult(1:length(aSc)) = 1;
adult = adult==1; child = ~adult;

for(ii=1:length(allSc))
   disp(['Processing ' allSc{ii} '...']);
   maskFile = fullfile(allDir{ii},'t1','t1_mask.nii.gz');
   if(exist(maskFile,'file'))
      ni = readFileNifti(maskFile);
      voxVol = prod(ni.pixdim(1:3));
      brainVolCc(ii) = sum(ni.data(:)>0.5).*voxVol./1000;
   else
      brainVolCc(ii) = NaN;
   end
end
aMn = nanmean(brainVolCc(adult));
aSd = nanstd(brainVolCc(adult));
cMn = nanmean(brainVolCc(child));
cSd = nanstd(brainVolCc(child));
[p,t,df] = myStatTest(brainVolCc(adult),brainVolCc(child),'t');
fprintf('\nAdult = %0.0f cc (%0.2f)\nChild = %0.0f cc (%0.2f)\nchild/adult ratio = %0.3f\nt-test: t=%0.2f, p=%0.4g (p<10^-%d), df=%d\n\n',...
	aMn,aSd,cMn,cSd,cMn./aMn,t,p,floor(-log10(p)),df);


for(ii=1:length(allSc))
  if(isempty(strmatch(allSc{ii},subCode)))
    adult(ii) = 0; child(ii) = 0;
  end
end


behavDataFile = fullfile(baseDir,'read_behav_measures_longitude.csv');
[bd,bdColNames] = dtiGetBehavioralData(allSc,behavDataFile);
for(ii=1:length(bdColNames))
  [p,r,df] = statTest(bd(child,ii)',brainVolCc(child),'r');
  fprintf('%s vs. brain volume: r=%0.2f, p=%0.4g (p<10^-%d), df=%d\n',bdColNames{ii},r,p,floor(-log10(p)),df);
end

male = bd(:,1)'==1; male(isnan(male))=false;


aMn = mean(brainVolCc(adult&male));
aSd = std(brainVolCc(adult&male));
cMn = mean(brainVolCc(child&male));
cSd = std(brainVolCc(child&male));
[p,t,df] = statTest(brainVolCc(adult&male),brainVolCc(child&male),'t');
fprintf('\nMales:\nAdult = %0.0f cc (%0.2f)\nChild = %0.0f cc (%0.2f)\nchild/adult ratio = %0.3f\nt-test: t=%0.2f, p=%0.4g (p<10^-%d), df=%d\n\n',...
	aMn,aSd,cMn,cSd,cMn./aMn,t,p,floor(-log10(p)),df);

aMn = mean(brainVolCc(adult&~male));
aSd = std(brainVolCc(adult&~male));
cMn = mean(brainVolCc(child&~male));
cSd = std(brainVolCc(child&~male));
[p,t,df] = statTest(brainVolCc(adult&~male),brainVolCc(child&~male),'t');
fprintf('\nFemales:\nAdult = %0.0f cc (%0.2f)\nChild = %0.0f cc (%0.2f)\nchild/adult ratio = %0.3f\nt-test: t=%0.2f, p=%0.4g (p<10^-%d), df=%d\n\n',...
	aMn,aSd,cMn,cSd,cMn/aMn,t,p,floor(-log10(p)),df);
