function [anat, inplanes] = GetAnatomyFromAnalyze(fileName)
% [anat, inplanes] = GetAnatomyFromAnalyze(fileName)
%
% Similar to getAnatomy but you pass in a 3d Analyze / nifti file that you
% already made. Requires SPM5
% ARW 061407

anat = [];

if ~exist(fileName, 'file'); 
    disp(fileName);
    disp('File does not exist')
    
    return;
end

    V=spm_vol(fileName);
    
    [anat,XYZ] = spm_read_vols(V);
      % Do a rot90 on each slice of the anat. That's just the way it is...
    for thisSlice=1:size(anat,3)
        anat2(:,:,thisSlice)=rot90(anat(:,:,thisSlice),1);
    end
    anat=anat2;
    
    % Use imatrix to recover slice spacing etc.
    [inTrans]=spm_imatrix(V.mat);
    
    sz = size(anat);
    mm=abs(inTrans(7:9));
    
    inplanes.FOV = mm(1)*sz(1);
    inplanes.fullSize = sz(1:2);
    inplanes.voxelSize = mm;
    inplanes.spacing = 0;
    % We already checked hdr.image.slquant==nList, not again -- Junjie
    inplanes.nSlices = sz(3);

    inplanes.examNum = V.descrip;
    inplanes.crop = [];
    inplanes.cropSize = [];

    
  
