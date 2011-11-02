
subDir = '/biac2/wandell2/data/reading_longitude/dti/*';
excludeSubs = {'dh040607','an041018','hy040602','lg041019','mh040630','tk040817'};
[f,sc] = findSubjects(subDir,'*_dt6_noMask',excludeSubs);
n = length(sc);
for(ii=1:n)
  d = load(f{ii},'anat');
  img{ii} = d.anat.img;
  imgAc{ii} = mrAnatXformCoords(inv(d.anat.xformToAcPc),[0 0 0]);
end


clear ms
for(ii=1:n)
  ac = imgAc{ii};
  tmp = squeeze(img{ii}(ac(1),:,:));
  ms(:,:,ii) = tmp(ac(2)-118:ac(2)+87, ac(3)-59:ac(3)+90);
end

ms = flipdim(flipdim(permute(ms,[2 1 3]),1),2);
sz = size(ms);

winSz = 18;
g = gausswin(winSz*2);
g = [ones(sz(1)-winSz-2,1); g(winSz:end); 0];
g = repmat(g,[1,sz(2),sz(3)]);
ms = double(ms).*g;

ms = vertcat(ones(10,sz(2),sz(3)),ms);

showMontage(ms)

badIms = [1 19 25 43];
middleIms = [21 22 27 28];
sl = [1:48];
sl(middleIms) = badIms;
sl(badIms) = middleIms;
%sl = [1:6,33,8:21,31,23,24,27,28,7,25,29,26,30,22,32,34:47,49]; 
%m=makeMontage3(ms,sl,[],1,[],6);

m=makeMontage3(ms,sl,[],2,[],8);
image(m);


imwrite(uint8(round(m*255)),gray(256),'/biac1/wandell/docs/2007_Reading_DTI_Dougherty/coverArt/everyBrain_landscape.png');
