% this script will get you the volume of a fg,
% if you do the following steps before running:
% load dt6
% load fg
% analyze>fibers>compute fiber density

dtiFig = gcf;
h = guidata(dtiFig);

%get current fiber density volume
fdName = 'fiber density';
imgNum = dtiGet(h,'namedimagenum',fdName);
img = dtiGet(h,'backgroundImage',imgNum);
crit = [0]; %no need to threshold if its one fiber group, not big. if you wish to threshold the density map, set this to .2 for example
for ii=1:length(crit)
    l = (img(:) > crit(ii));
    FgDensityVol(ii) = sum(l);
end
FgDensityVol