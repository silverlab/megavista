

bd = '/biac3/wandell4/data/reading_longitude/dti_y4/';
[sd,sc] = findSubjects([bd '*'],'dti06trilinrt');

outDir = '/biac3/wandell4/data/reading_longitude/spm_analysis';
if(~exist(outDir,'dir')), mkdir(outDir); end
outDirSubs = fullfile(outDir,'subFiles');
if(~exist(outDirSubs,'dir')), mkdir(outDirSubs); end
sumFile = fullfile(outDir,['sum_' datestr(now,'yymmdd')]);

n = numel(sd);
templateName = 'SIRL54';
templateDir = fullfile(fileparts(which('mrDiffusion.m')),'templates');
template = fullfile(templateDir, [templateName '_EPI.nii.gz']);
t1Template = fullfile(templateDir, [templateName '_T1.nii.gz']);
desc = ['Normalized to ' templateName ' using B0.'];
clear templateName templateDir sn t1Sn mB0 mT1 mFa;
mB0 = 0;
mFa = 0;
mBm = 0;
mT1 = 0;
for(ii=1:n)
    tic;
    dataDir = sd{ii};
    fprintf('Processing %d of %d (%s)...\n',ii, n, dataDir);
    dtiRawFixDt6File(dataDir);
    [dt,t1] = dtiLoadDt6(dataDir);
    im = mrAnatHistogramClip(double(dt.b0),0.4,0.98);
    dt.b0 = im;
    im(bwareaopen(im==0,10000,6)) = NaN;
    evalc('sn{ii} = mrAnatComputeSpmSpatialNorm(im, dt.xformToAcpc, template);');
    sn{ii}.VG.dat = [];
    b0 = mrAnatResliceSpm(dt.b0,sn{ii},dt.bb,dt.mmPerVoxel,1,false);
    [fa,md,rd,ad] = dtiComputeFA(double(dt.dt6));
    [fa,dtXformToAcpc] = mrAnatResliceSpm(fa,sn{ii}, dt.bb, dt.mmPerVoxel, 1, false);
    md = mrAnatResliceSpm(md,sn{ii},dt.bb,dt.mmPerVoxel,1,false);
    rd = mrAnatResliceSpm(rd,sn{ii},dt.bb,dt.mmPerVoxel,1,false);
    ad = mrAnatResliceSpm(ad,sn{ii},dt.bb,dt.mmPerVoxel,1,false);
    bm = mrAnatResliceSpm(double(dt.brainMask),sn{ii},dt.bb,dt.mmPerVoxel,1,false);
    
    adcUnits = dt.adcUnits;
    mB0 = mB0 + b0;
    mFa = mFa + fa;
    mBm = mBm + bm;
    outName = fullfile(outDirSubs,[sc{ii} '_']);
    dtiWriteNiftiWrapper(single(b0),dtXformToAcpc,[outName 'b0']);
    dtiWriteNiftiWrapper(single(fa),dtXformToAcpc,[outName 'fa']);
    dtiWriteNiftiWrapper(single(md),dtXformToAcpc,[outName 'md']);
    %dtiWriteNiftiWrapper(single(rd),dtXformToAcpc,[outName 'rd']);
    %dtiWriteNiftiWrapper(single(ad),dtXformToAcpc,[outName 'ad']);    
    %dtiWriteNiftiWrapper(uint8(bm*255),dtXformToAcpc,[outName 'bm'],1/255);
    
    clear dt im;
    im = mrAnatHistogramClip(double(t1.img),0.4,0.98);
    evalc('t1Sn{ii} = mrAnatComputeSpmSpatialNorm(im, t1.xformToAcpc, t1Template);');
    t1Sn{ii}.VG.dat = [];
    [im,t1XformToAcpc] = mrAnatResliceSpm(im, t1Sn{ii}, mrAnatXformCoords(t1Sn{ii}.VG.mat,[1 1 1; t1Sn{ii}.VG.dim]), [1 1 1], 1, false);
    mT1 = mT1 + im;
    %dtiWriteNiftiWrapper(single(im),t1XformToAcpc,[outName 't1']);
    clear im t1;
    toc
end
outName = fullfile(outDir,[sc{ii} '_']);
dtiWriteNiftiWrapper(single(mB0),dtXformToAcpc,[outName 'mB0']);
dtiWriteNiftiWrapper(single(mFa),dtXformToAcpc,[outName 'mFa']);
dtiWriteNiftiWrapper(single(mBm),dtXformToAcpc,[outName 'mBm']);
dtiWriteNiftiWrapper(single(mT1),t1XformToAcpc,[outName 'mT1']);    


