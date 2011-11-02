function P = dtiSignalLossMatrix(Q,bvecs,bvals)
%Compute the signal loss in each direction (bvecs) for a set of tensors (Q)
%
%   P = dtiSignalLossMatrix(Q,bvecs,bvals)
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
P = zeros(nDirs,nFibers);

bvecs = diag(bvals.^0.5)*bvecs;

for ii=1:nFibers
    q = reshape(Q(ii,:),3,3);
    P(:,ii) = diag(bvecs*q*bvecs');
end

return