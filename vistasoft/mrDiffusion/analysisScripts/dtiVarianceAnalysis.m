clear all
type = 'myT1';
outDir = '/biac2/wandell2/data/templates/varianceAnalysis/';
slices = [-10:4:50];
switch(type)
 case 'acpc',
  baseDir = '/biac2/wandell2/data/reading_longitude/dti_adults/*0*';
  [files,subCodes] = findSubjects(baseDir, '*_dt6',{'ah051003','gf050826'});
  typeName = 'AC-PC';
 case 'myT1',
  baseDir = '/biac2/wandell2/data/templates/adult/SIRL20_adultwarp2';
  [files,subCodes] = findSubjects(baseDir, '*sn*',{'average_dt6'});
  typeName = 'SIRL20_T1';
end

N = length(files);

dt = load(files{1},'b0');
sz = size(dt.b0);
b0 = zeros([sz N]);
fa = zeros([sz N]);
md = zeros([sz N]);
pdd = zeros([sz 3 N]);
for (ii=1:N)
  disp(['Processing ' subCodes{ii} '...']);
  dt = load(files{ii});
  dtXform(:,:,ii) = dt.xformToAcPc;
  b0(:,:,:,ii) = double(dt.b0);
  [evec,eval] = dtiSplitTensor(dt.dt6);
  [fa(:,:,:,ii),md(:,:,:,ii)] = dtiComputeFA(eval);
  pdd(:,:,:,:,ii) = evec(:,:,:,:,1);
end
%Clear out NANs
b0(isnan(b0(:))) = 0;
md(isnan(md(:))) = 0;
fa(isnan(fa(:))) = 0;
pdd(isnan(pdd(:))) = 0;
if(any(any(sum(diff(dtXform,1,3),3))))
  error('Not all dtXforms are identical!');
else
  xform = dtXform(:,:,1);
end
sl = mrAnatXformCoords(inv(xform),[zeros([2 length(slices)]); slices]');
sl = round(sl(:,3));

mnB0 = mean(b0,4);
sdB0 = std(b0,1,4);
mnFA = mean(fa,4);
sdFA = std(fa,1,4);
mnMd = mean(md,4);
sdMd = std(md,1,4);
%mask = dtiCleanImageMask(mnFA>.05,3);
[mask,bmSl] = mrAnatExtractBrain(mnB0, [2,2,2], 0.5);
mnFa(~mask) = 0; sdFa(~mask) = 0;
mnMd(~mask) = 0; sdMd(~mask) = 0;

[mnPdd,dispPdd] = dtiDirMean(pdd,mask);
% Convert the PDD dispersion from arbitrary units to an angle
dispPdd = asin(sqrt(dispPdd))./pi.*180;
dispPdd(isnan(dispPdd)) = 0;

% Upsample level (1=2x, 2=4x, ...)
us = 1;

makeMontage3(mnB0,sl,2,us); set(gcf,'name',[typeName '_mean B0']);
makeMontage3(sdB0,sl,2,us); set(gcf,'name',[typeName '_std B0']);

makeMontage3(mnFA,sl,2,us); set(gcf,'name',[typeName '_mean FA']);
mx = max(sdFA(:)); im = sdFA./mx;
mrUtilMakeColorbar(gray(256),linspace(0,mx,5),'FA Stdev');
makeMontage3(im,sl,2,us); set(gcf,'name',[typeName '_std FA']);
makeMontage3(mnMd,sl,2,us); set(gcf,'name',[typeName '_mean MD']);
makeMontage3(sdMd,sl,2,us); set(gcf,'name',[typeName '_std MD']);

im = abs(mnPdd); sc = mnFA.^0.8; im = im.*repmat(sc,[1 1 1 3]);
makeMontage3(im,sl,2,us); set(gcf,'name',[typeName '_mean PDD']);
mx = max(dispPdd(:)); im = dispPdd./mx;
makeMontage3(im,sl,2,us); set(gcf,'name',[typeName '_std PDD']);

figure; 
subplot(3,2,1); hist(mnMd(mask(:)),100);
subplot(3,2,2); hist(sdMd(mask(:)),100);
subplot(3,2,3); hist(mnFA(mask(:)),100);
subplot(3,2,4); hist(sdFA(mask(:)),100);
subplot(3,2,5); hist(mnPdd(mask(:)),100);
subplot(3,2,6); hist(dispPdd(mask(:)),100)

bg = mnB0; bg(~mask) = 0; bg = mrAnatHistogramClip(bg,.5,.99);
lowVarRegions = (sdMd<300) & (sdFA<.15) & (dispPdd<25) & mask;
im(:,:,:,1) = double(lowVarRegions);
im(:,:,:,2) = bg; im(:,:,:,3) = bg; 
makeMontage3(im,sl,2,us);

t = 0.5;
mdThresh = 250;
faThresh = 0.10;
pddThresh = 20;

im(:,:,:,1) = double(sdFA<faThresh&dispPdd>=pddThresh&mask).*t + bg.*(1-t);
im(:,:,:,2) = double(sdFA<faThresh&dispPdd<pddThresh&mask).*t + bg.*(1-t);
im(:,:,:,3) = double(dispPdd<pddThresh&sdFA>=faThresh&mask).*t + bg.*(1-t);
m = makeMontage3(im,sl,2,us); set(gcf,'name',[typeName ' FA vs. PDD']);
imwrite(m, fullfile(outDir, [typeName '_FAvPDD.png']));

im(:,:,:,1) = double(sdMd<mdThresh&dispPdd>=pddThresh&mask).*t + bg.*(1-t);
im(:,:,:,2) = double(sdMd<mdThresh&dispPdd<pddThresh&mask).*t + bg.*(1-t);
im(:,:,:,3) = double(dispPdd<pddThresh&sdMd>=mdThresh&mask).*t + bg.*(1-t);
m = makeMontage3(im,sl,2,us); set(gcf,'name',[typeName ' MD vs. PDD']);
imwrite(m, fullfile(outDir, [typeName '_MDvPDD.png']));

im(:,:,:,1) = double(sdFA<faThresh|sdMd<mdThresh&dispPdd>=pddThresh&mask).*t + bg.*(1-t);
im(:,:,:,2) = double(sdFA<faThresh&sdMd<mdThresh&dispPdd<pddThresh&mask).*t + bg.*(1-t);
im(:,:,:,3) = double(dispPdd<pddThresh&sdMd>=mdThresh|sdFA>=faThresh&mask).*t + bg.*(1-t);
m = makeMontage3(im,sl,2,us); set(gcf,'name',[typeName ' FA & MD vs. PDD']);
imwrite(m, fullfile(outDir, [typeName '_MD&FAvPDD.png']));

