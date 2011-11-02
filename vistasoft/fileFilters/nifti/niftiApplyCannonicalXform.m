function [ni,canXform] = niftiApplyCannonicalXform(ni, canXform, phaseDir)
% Reorient NIFTI data and metadata fields according to a simple xform 
%
%    [ni,canXform] = ...
%       niftiApplyCannonicalXform(ni, ...
%          [canXform=mrAnatComputeCannonicalXformFromDicomXform], phaseDir=[])
%
% Given a NIFTI-1 file ni- reorients the data and adjusts relevent metadata
% fields (like quaternion, pixfdim, freq/phase/slice dims, etc.). If the
% canXform isn't provided, it is computed using
% mrAnatComputeCannonicalXformFromDicomXform.
%
% You can also pass the phase dir to overwrite a bad phase_dir field in
% your nifti header. Note that you should specify the phase_dir of the
% input data *before* the cannonical xform is applied. The value should be
% 1, 2, or 3 to specify phase-encoding along the first, second or third
% image dimension.
%
% See mrAnatComputeCannonicalXformFromDicomXform and applyCannonicalXform
% for more details.
%
% HISTORY:
% 2007.05.17 RFD: wrote it.
% 2008.08.15 RFD: fixed dim order bug.

if(nargin<1), help(mfile); end

% Do a sanity-check on the nifti transform
ni = niftiCheckQto(ni);

if(~exist('canXform','var') || isempty(canXform))
    canXform = mrAnatComputeCannonicalXformFromDicomXform(ni.qto_xyz, ni.dim(1:3));
end
%canXform(:,4) = [0 0 0 1]';
if(exist('phaseDir','var') && ~isempty(phaseDir))
    ni.phase_dim = phaseDir;
end

if(all(all(canXform == eye(4))))
  disp('Data are already in cannonical orientation.');
else
    
    % Apply the transform
    [ni.data,newPixdim,dimOrder,dimFlip] = ...
        applyCannonicalXform(ni.data, canXform, ni.pixdim(1:3), false);
    
    % Fill the NIFTI image slots
    ni.dim = size(ni.data);
    ni.pixdim(1:3) = newPixdim;
    ni = niftiSetQto(ni, inv(canXform*ni.qto_ijk));
    if(any(ni.sto_xyz(:)>0))
        ni.sto_ijk = canXform*ni.sto_ijk;
        ni.sto_xyz = inv(ni.sto_ijk);
    end
    if(ni.freq_dim>0&&ni.freq_dim<4)
        ni.freq_dim = dimOrder(ni.freq_dim);
    else
        warning('freq_dim not set correctly in NIFTI header.');
    end
    if(ni.phase_dim>0&&ni.phase_dim<4)
        ni.phase_dim = dimOrder(ni.phase_dim);
    else
        warning('phase_dim not set correctly in NIFTI header.');
    end
    if(ni.slice_dim>0&&ni.slice_dim<4)
        ni.slice_dim = dimOrder(ni.slice_dim);
    end
end

return;
