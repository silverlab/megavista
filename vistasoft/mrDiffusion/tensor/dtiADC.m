function ADC = dtiADC(Q,bvecs)
%Compute the ADC in each direction (bvecs) for a set of tensors (Q)
%
%   ADC = dtiADC(Q,bvecs)
% 
% The rows of Q are 3x3 tensors at a point in one fiber. The bvecs and
% bvals are the measurement directions and bvals used to calculate the
% tensor. These can be read using dtiLoadDWI (see s_mictSimple).
%
% These tensors describe how each fiber should contribute to the total
% signal loss at that point.
%
% Examples:
%  TODO
%
% See also: fgTensors, t_mrd, s_mictDirectionBasis, s_mictSimple
%
% (c) Stanford VISTA Team
%
% Check whether the units are properly preserved here, in terms of the
% square root of bvals.  This should be checked with fgTensors, which is
% the way the computation is done.

if notDefined('Q'), error(''); end

nFibers = size(Q,1);
nDirs = size(bvecs,1);
ADC = zeros(nDirs,nFibers);

% Signal equation:
%  dSig = S0 exp(-bval*(bvec*Q*bvec))
%  ADC = diag(bvec*Q*bvec')
for ii=1:nFibers
    q = reshape(Q(ii,:),3,3);
    ADC(:,ii) = diag(bvecs*q*bvecs');
end

return