function ni = niftiCheckQto(ni)
%  Sanity-check the qto transform in the nifti struct ni
% ni = niftiCheckQto(ni)
%
% Does a simple sanity-check on the xform. Right now, we check the origin to
% make sure it iswell- within the image volume. If not, the qto xform
% fields of the NIFTI struct ni will be adjusted to set the origin to the
% center of the image. The updated struct is returned and a message is
% printed to the command line indicating the fix. 
%
% HISTORY:
% 2007.07.18 RFD: wrote it.
% 2011.07.20 LMP: RFD added a check for the qform_code that will call
% niftiSetQto if the qform_code=0. This was added to deal specifically with
% data from seimens scanners. 
%

if(isfield(ni,'data')&&~isempty(ni.data))
    % sanity-check ni.dim
    sz = size(ni.data);
    if(any(ni.dim(1:3)~=sz(1:3)))
        disp('NIFTI volume dim wrong- setting it to the actual data size.');
        ni.dim(1:3) = sz(1:3);
    end
end

if(ni.qform_code==0 && ni.sform_code~=0)
    disp('qform_code is zero; setting .');
    ni = niftiSetQto(ni, ni.sto_xyz);
end

origin = [ni.qto_ijk(1:3,:)*[0 0 0 1]']';
if(any(origin<2)||any(origin>ni.dim(1:3)-2))
    disp('NIFTI header origin is at or outside the image volume- setting it to the image center.');
    [t,r,s,k] = affineDecompose(ni.qto_ijk);
    t = ni.dim/2;
    ni = niftiSetQto(ni, inv(affineBuild(t,r,s,k)));
end
    
return;