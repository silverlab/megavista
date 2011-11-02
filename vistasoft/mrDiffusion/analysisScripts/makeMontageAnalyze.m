
[f,s]=findSubjects([],[],[]);
n = 0;
for(ii=1:length(f))
  ad = fullfile(fileparts(f{ii}), 't1', [s{ii} '_t1anat_avg.img']);
  disp(['Loading ' s{ii} '...']);
  if(exist(ad,'file'))
    [im,mm,hd] = loadAnalyze(ad);
    n = n+1;
    ac = round(inv(hd.mat)*[0 0 0 1]');
    ax(:,:,n) = flipud(permute(squeeze(im(:,:,ac(3))),[2,1]));
    cr(:,:,n) = flipud(permute(squeeze(im(:,ac(2),:)),[2,1]));
    sg(:,:,n) = fliplr(flipud(permute(squeeze(im(ac(1),:,:)),[2,1])));
    l{n} = s{ii};
  else
    disp('Skipping...');
  end
end

sg = sg./max(sg(:));
cr = cr./max(cr(:));
ax = ax./max(ax(:));
msg = makeMontage3(sg, sg, sg, [], 1, 1, l);
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r90', 'allSag.png');
mcr = makeMontage3(cr, cr, cr, [], 1, 1, l);
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r90', 'allAxl.png');
max = makeMontage3(ax, ax, ax, [], 1, 1, l);
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, '-dpng', '-r90', 'allCor.png');
%imwrite(msg,'allSag.png');
%imwrite(mcr,'allSag.png');
%imwrite(max,'allSag.png');