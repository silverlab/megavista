
% See dtiGenerateNormalizedData.m for an example of how to generate the
% summary file used here.

bd = '/biac3/wandell4/data/reading_longitude/logNorm_analysis';
sumFile = fullfile(bd,'sum_090206');
datSum = load(sumFile);
outDir = fullfile(bd,'figs');

%vec = load('/white/u6/armins/matlab/dtiAnalysis165/logPValImg_vec');
group = {'b','g'};
slice = [49]; % 49 or 50 (z= 36 or 38)
z = datSum.dtXformToAcpc*[0 0 slice 1]'; z = z(3);
bgColor = 0;

p=[131,82];
% Two-sample test
for(ii=1:numel(group))
    if(ii==1), [vec,val] = dtiEig(datSum.dt6(:,:,datSum.isBoy==1));
    else,      [vec,val] = dtiEig(datSum.dt6(:,:,datSum.isBoy==0)); end
    for(jj=1:2)
        [Mdir, Sdir, Ndir, SbarDir] = dtiDirMean(squeeze(vec(:,[1 2 3],jj,:)));
        fa = dtiComputeFA(val);
        mnFa = mean(fa,2);
        mnFaIm = dtiIndToImg(mnFa,datSum.brainMask,1);
        im = dtiIndToImg(abs(Mdir).*repmat(mnFa,[1 3]),datSum.brainMask,bgColor);
        %m = makeMontage3(flipdim(permute(im,[2 1 3 4]),1), slice, [], 2, [], [], 1);
        im = flipdim(permute(im,[2 1 3 4]),1);
        m = squeeze(im(:,:,slice,:));
        m = mrAnatAutoCrop(m,2); 
        clear ms; for(kk=1:3), ms(:,:,kk) = upSample(m(:,:,kk),2); end
        figure(1); clf; image(ms); axis tight off; truesize;
        hold on; plot(p(2),p(1),'ok','LineWidth',2,'MarkerSize',20,'MarkerEdgeColor',[1 1 .9]);
        fn = fullfile(outDir,sprintf('%sv%d_z%d',group{ii},jj,z));
        mrUtilPrintFigure([fn '.eps']);
        %imwrite(uint8(round(m.*255)),[fn '.tif']);
        %unix(['tiff2ps -e ' fn '.tif > ' fn '.eps']);
    end
end

ims = {'full','val','vec','vec_b5'};
for(ii=1:numel(ims))
    load(['/home/armins/matlab/dtiAnalysis165/logPValImg_' ims{ii}]);
    logPValImg = flipdim(permute(logPValImg,[2 1 3 4]),1);
    m = logPValImg(:,:,slice);
    m = mrAnatAutoCrop(m,2); %m = upSample(m,2);
    m(m>5) = 5; m = uint8(round(m./5.*255));
    figure(1); clf;
    image(m); axis tight off; truesize; colormap(gray(256));
    fn = fullfile(outDir,sprintf('%s_spm_z%d',ims{ii},z));
    mrUtilPrintFigure([fn '.eps']);
    mrUtilMakeColorbar(gray(256),[0:1:5]','-log10(p)', [fn '_legend.eps']);
end

load('/home/armins/matlab/dtiAnalysis165/sImg');
sImg = flipdim(permute(sImg,[2 1 3 4]),1);
m = sImg(:,:,slice);
m = mrAnatAutoCrop(m,2); m = upSample(m,2);
m(m>0.1) = 0.1; m = uint8(round(m./0.1.*255));
figure(1); clf;
image(m); axis tight off; truesize; colormap(gray(256));
fn = fullfile(outDir,sprintf('S_z%d',z));
mrUtilPrintFigure([fn '.eps']);
mrUtilMakeColorbar(gray(256),[0,0.02,0.04,0.06,0.08,0.10]','', [fn '_legend.eps']);


% Thresh: smooth=2.35, unsmoothed=2.96
load('/home/armins/matlab/dtiAnalysis165/logPValImg_vec');
%imgRgb = mrAnatOverlayMontage(logPValImg, datSum.dtXformToAcpc, datSum.mT1, datSum.t1XformToAcpc, autumn(256), [2.35,8], [0:2:40], [], [], [], true, 0);
fn = fullfile(outDir,sprintf('vecSpm_overlay_z%d',z));
thresh = 2.96;
imgRgb = mrAnatOverlayMontage(logPValImg, datSum.dtXformToAcpc, datSum.mT1, datSum.t1XformToAcpc, autumn(256), [thresh,8], [z], [], [], [], false, 0);
mrUtilPrintFigure([fn '.eps']);
x = round(thresh/8*256);
mrUtilMakeColorbar([zeros(x,3); autumn(256-x)],[0:2:8]','', [fn '_legend.eps']);

load('/home/armins/matlab/dtiAnalysis165/logPValImg_vec_b5');
%imgRgb = mrAnatOverlayMontage(logPValImg, datSum.dtXformToAcpc, datSum.mT1, datSum.t1XformToAcpc, autumn(256), [2.35,8], [0:40], [], [], [], true, 0);
fn = fullfile(outDir,sprintf('vecB5Spm_overlay_z%d',z));
thresh = 2.35;
imgRgb = mrAnatOverlayMontage(logPValImg, datSum.dtXformToAcpc, datSum.mT1, datSum.t1XformToAcpc, autumn(256), [thresh,8], [z], [], [], [], false, 0);
mrUtilPrintFigure([fn '.eps']);
x = round(thresh/8*256);
mrUtilMakeColorbar([zeros(x,3); autumn(256-x)],[0:2:8]','', [fn '_legend.eps']);

