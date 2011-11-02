function rx = rxKNKauto(rx)

mrGlobals;

% do it automatically
knk = rx.knk;
useMutualInformation = true;
alignvolumedata_auto(knk.mn,knk.sd,0,[4 4 2], [], [], [], useMutualInformation);
rx.knk.trNEW = alignvolumedata_exporttransformation;

% convert to 4x4 transformation matrix for use in mrVista
rx.knk.xform = transformationtomatrix(rx.knk.trNEW,0,rx.volVoxelSize);
rx = rxKNK2mrRx(rx);
end