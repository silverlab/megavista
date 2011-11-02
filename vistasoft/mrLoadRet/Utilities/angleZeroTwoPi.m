function phData = angleZeroTwoPi(cxData)
%
%  phData = angleZeroTwoPi(cxData)
%
% Author: Wandell, Brewer
% Purpose:
%    The Matlab angle function returns values between -pi and pi.
%
%    This function  returns  angles between [0 , 2pi], consistent with many
%    mrLoadRet/mrVista functions.
%

phData = angle(cxData);

l = phData < 0;

phData(l) = phData(l) + 2*pi;

return;