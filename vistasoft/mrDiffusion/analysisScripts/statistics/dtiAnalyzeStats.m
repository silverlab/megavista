% dtiAnalyzeStats
% Performs statistical analysis on FA maps of groups
% Output: Saves out stat file of r values and Fisher's z values

s = findSubjects;

for(ii=1:length(s))
    [p,f,e] = fileparts(s{ii});
    dt6FileNameList{ii} = f;
    dt6FilePathList{ii} = p;
    us = findstr('_',f);
    subCode{ii} = f(1:us(1)-1);
end

behData = readTab('/snarp/u1/data/reading_longitude/read_behav_measures.csv',',',1);
nSubs = 0;
for(ii=1:size(behData,1))
    sc = deblank(behData{ii,2});
    if(~isempty(sc))
        tmp = strmatch([sc '0'], subCode);
        if(~isempty(tmp))
            nSubs = nSubs + 1;
            dt6FileInd(nSubs) = tmp(1);
            basicRead(nSubs) = behData{ii,3};
        end
    end
end

for (ii=1:length(dt6FileInd))
    faFile = fullfile(dt6FilePathList{dt6FileInd(ii)}, 'mhoRegistration050110', [subCode{dt6FileInd(ii)} '_reg2_mhoTemplateIter1_FAMap.img']);
    [fa_img(:,:,:,ii), fa_mm, fa_hdr] = loadAnalyze(faFile);
end

fa_img(isnan(fa_img(:))) = 0;

mn_fa = mean(fa_img, 4);
sd_fa = std(fa_img, 1, 4);

mn_rs = mean(basicRead);
sd_rs = std(basicRead);

fa_Z = (fa_img-repmat(mn_fa, [1 1 1 nSubs])) ./ repmat(sd_fa, [1 1 1 nSubs]);
rs_Z = (basicRead-mn_rs) ./ sd_rs;

r = 0;
for(ii=1:nSubs)
    r = r + fa_Z(:,:,:,ii).*rs_Z(ii);
end
r = r./nSubs;

% compute Fischer's z'
z = 0.5*(log((1+r)./(1-r)));
df = nSubs-3;
p = erfc((abs(z)*sqrt(df))/sqrt(2));

%Saving out file
stat{1} = r; stat{2} = z; stat{3} = p;
statName{1} = 'r'; statName{2} = 'z'; statName{3} = 'p';
atlas = 'snarp/u1/data/dti/childData/Registration/allSubjectRegistration/mhoTemplate_Iter1.mat';
notes = 'Correlation with basic reading';

filename = 'basicReadingMaps051201';
save(filename,stat,statName,atlas,notes);


% m = makeMontage(r, [20:60]); figure; imagesc(m); axis image; colorbar;
% 
% mask = p<0.05;
% 
% 
% p_norm = -log10(p);
% p_norm = p_norm./max(p_norm(:));
% p_norm = round(p_norm*255+1);
% cmap = hot(256);
% R = mn_fa; G = mn_fa; B = mn_fa;
% R(mask) = cmap(p_norm(mask),1);
% G(mask) = cmap(p_norm(mask),2);
% B(mask) = cmap(p_norm(mask),3);
% im = makeMontage3(R,G,B,[20:60], 2);
% %figure; image(uint8(im)); axis image;
% cbar = [0:.05:1];
% figure; imagesc(cbar); colormap(cmap);
% 
% r_norm = (r+1)./2;
% r_norm = round(r_norm*255+1);
% cmap = cool(256);
% R = mn_fa; G = mn_fa; B = mn_fa;
% R(mask) = cmap(p_norm(mask),1);
% G(mask) = cmap(p_norm(mask),2);
% B(mask) = cmap(p_norm(mask),3);
% im = makeMontage3(R,G,B,[20:60], 2);
% cbar = [-1:.05:1];
% figure; imagesc(cbar); colormap(cmap);
 