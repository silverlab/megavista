spm_defaults;
defaults.analyze.flip = 0;

h2 = guidata(3);

VG.uint8 = uint8(h1.bg(4).img*255+0.5);
VG.mat = h1.acpcXform;
VF.uint8 = uint8(h2.bg(4).img*255+0.5);
VF.mat = h2.acpcXform;
p = defaults.coreg.estimate;
transRot = spm_coreg(VG,VF,p);
%transRot(1:3) = transRot(1:3)+mmDt/2;
xform = spm_matrix(transRot(:)');


fg = dtiReadFibers([], [], xform);
h2 = dtiAddFG(fg,h2);

guidata(h2.fig,h2);

mrmRotateCamera(2,[pi/2 pi pi/2]);