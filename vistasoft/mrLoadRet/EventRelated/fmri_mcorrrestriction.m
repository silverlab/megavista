function RMC = fmri_mcorrestriction(RM,TR,nHEst,Delta,Tau)
%
% RMC = fmri_mcorrestriction(RM,TR,nHEst,Delta,Tau)
%
% Creates a restriction matrix for correlating with a
% hemodynmic response function (HRF).  The HRF is
% computed using a Gamma function with parameters 
% Delta and Tau over the estimation time window.
%
% RM is a restriction matrix created by CreateRM.
%
% See also: CreateRM(), HemoDyn()
%
% $Id: fmri_mcorrrestriction.m,v 1.1 2004/03/11 01:30:16 sayres Exp $


t = TR*[0:nHEst-1]';
hHDIR = fmri_hemodyn(t,Delta,Tau);
nCond = size(RM,2)/nHEst; % excluding fix %
q = repmat(hHDIR',size(RM,1),nCond);
RMC = RM .* q;

return;
