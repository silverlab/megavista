function rx = rxKNK2mrRx(rx)

mrGlobals;
xform = rx.knk.xform;
% shift = [eye(3) -rx.rxDims([2 1 3])'./2; 0 0 0 1];
% xform = shift*xform/shift;
    
% rx.prevXform = rx.xform;
% rx.xform = xform;

rx = rxSetXform(rx, xform);

rx = rxStore(rx,'KNK Align');


%% figures for comparing
% if ~exist('Images','dir'), mkdir('Images'); end    
% matchORIG = extractslices(rx.vol,rx.volVoxelSize,rx.ref,rx.refVoxelSize,rx.knk.TORIG);
% matchNEW  = extractslices(rx.vol,rx.volVoxelSize,rx.ref,rx.refVoxelSize,rx.knk.trNEW);
% imwrite(uint8(255*makeimagestack(matchORIG,1)),'Images/matchORIG.png');
% imwrite(uint8(255*makeimagestack(matchNEW,1)),'Images/matchNEW.png');
% imwrite(uint8(255*makeimagestack(rx.ref,1)),'Images/anat.png');

return
